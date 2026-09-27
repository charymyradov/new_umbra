/**
 * Umbra Auth Worker — "Umbra ile devam et" için token sunucusu.
 *
 * Akış (OAuth "authorization code + PKCE" benzeri):
 *
 *  1) LitList rastgele bir `verifier` üretir, `challenge = base64url(sha256(verifier))`
 *     hesaplar ve Umbra'yı açar:  umbra://authorize?app=litlist&challenge=...
 *
 *  2) Umbra (kullanıcı zaten giriş yapmış) izin ekranını gösterir. "İzin ver" denince:
 *        POST /approve
 *        Authorization: Bearer <Umbra kullanıcısının Firebase ID token'ı>
 *        { "app": "litlist", "challenge": "...", "scopes": ["identity.name", "reading.profile"] }
 *     → { "code": "...", "expires_in": 60 }
 *     Umbra, LitList'i açar:  litlist://callback?code=...
 *
 *  3) LitList:
 *        POST /token
 *        { "app": "litlist", "code": "...", "verifier": "..." }
 *     → { "token": "<Firebase custom token>", "uid": "..." }
 *     ve FirebaseAuth.signInWithCustomToken(token) çağırır.
 *     Artık Umbra'daki kullanıcıyla AYNI Firebase kullanıcısıdır; token'ında
 *     `app: "litlist"` ve `scopes` etiketleri vardır (Firestore kuralları bunu görür).
 *
 * Veritabanı gerekmez: `code`, Worker'ın kendi gizli anahtarıyla imzalanır (60 sn geçerli).
 *
 * Gizli değişkenler (wrangler secret):
 *   FIREBASE_CLIENT_EMAIL  — service account e-postası
 *   FIREBASE_PRIVATE_KEY   — service account private key (PEM)
 *   CODE_SECRET            — code imzalamak için rastgele uzun bir değer
 * Normal değişkenler (wrangler.toml [vars]):
 *   FIREBASE_PROJECT_ID    — ör. umbra-a97d8
 *   APP_SCOPES             — bağlanabilen uygulamalar ve her birinin isteyebileceği scope'lar:
 *                            { "litlist": ["identity.name", ...] }  (Umbra'daki kExternalApps ile aynı)
 */
import {
  b64urlEncode,
  decodeJwt,
  importHmacKey,
  importRsaPrivateKey,
  importRsaPublicJwk,
  signJwt,
  verifyJwt,
} from './jwt.js';

const GOOGLE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const CUSTOM_TOKEN_AUDIENCE =
  'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit';
const CODE_AUDIENCE = 'umbra-auth-code';
const CODE_TTL_SECONDS = 60;
const MAX_BODY_BYTES = 4096;

const CHALLENGE_RE = /^[A-Za-z0-9_-]{43}$/; // base64url(sha256) = 43 karakter
const VERIFIER_RE = /^[A-Za-z0-9_-]{43,128}$/; // PKCE (RFC 7636)
const SCOPE_RE = /^[a-z][a-z0-9_]*(\.[a-z0-9_*]+)*$/;
const APP_RE = /^[a-z][a-z0-9_-]{1,31}$/;

class HttpError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

// ---------------------------------------------------------------------------
// Yardımcılar
// ---------------------------------------------------------------------------

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

async function sha256Base64url(text) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(text),
  );
  return b64urlEncode(digest);
}

function safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function readJson(request) {
  const type = request.headers.get('content-type') || '';
  if (!type.includes('application/json')) {
    throw new HttpError(415, 'content_type_must_be_json');
  }
  const text = await request.text();
  if (text.length > MAX_BODY_BYTES) throw new HttpError(413, 'body_too_large');
  try {
    const body = JSON.parse(text);
    if (!body || typeof body !== 'object') throw new Error();
    return body;
  } catch {
    throw new HttpError(400, 'invalid_json');
  }
}

/** Uygulama → izinli scope kümesi. wrangler.toml'da tablo ya da JSON metni olabilir. */
function appScopes(env) {
  let raw = env.APP_SCOPES ?? {};
  if (typeof raw === 'string') {
    try {
      raw = JSON.parse(raw);
    } catch {
      raw = {};
    }
  }
  const out = new Map();
  for (const [app, scopes] of Object.entries(raw || {})) {
    if (APP_RE.test(app) && Array.isArray(scopes)) out.set(app, new Set(scopes.map(String)));
  }
  return out;
}

function requireEnv(env) {
  for (const key of [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_PRIVATE_KEY',
    'CODE_SECRET',
  ]) {
    if (!env[key]) throw new HttpError(500, `missing_config_${key}`);
  }
}

let codeKeyCache = { secret: null, key: null };
async function codeKey(env) {
  if (codeKeyCache.secret !== env.CODE_SECRET) {
    codeKeyCache = {
      secret: env.CODE_SECRET,
      key: await importHmacKey(env.CODE_SECRET),
    };
  }
  return codeKeyCache.key;
}

let privateKeyCache = { pem: null, key: null };
async function firebasePrivateKey(env) {
  if (privateKeyCache.pem !== env.FIREBASE_PRIVATE_KEY) {
    privateKeyCache = {
      pem: env.FIREBASE_PRIVATE_KEY,
      key: await importRsaPrivateKey(env.FIREBASE_PRIVATE_KEY),
    };
  }
  return privateKeyCache.key;
}

const nowSeconds = () => Math.floor(Date.now() / 1000);

// ---------------------------------------------------------------------------
// Firebase ID token doğrulama (Admin SDK olmadan)
// ---------------------------------------------------------------------------

let jwksCache = { keys: null, expiresAt: 0 };

async function googlePublicKey(kid) {
  const now = Date.now();
  if (!jwksCache.keys || now >= jwksCache.expiresAt) {
    const res = await fetch(GOOGLE_JWKS_URL);
    if (!res.ok) throw new HttpError(502, 'google_keys_unavailable');
    const body = await res.json();
    const maxAge = /max-age=(\d+)/.exec(res.headers.get('cache-control') || '');
    jwksCache = {
      keys: Array.isArray(body.keys) ? body.keys : [],
      expiresAt: now + (maxAge ? Number(maxAge[1]) * 1000 : 3600 * 1000),
    };
  }
  const jwk = jwksCache.keys.find((k) => k.kid === kid);
  if (!jwk) throw new HttpError(401, 'invalid_id_token');
  return importRsaPublicJwk(jwk);
}

async function verifyFirebaseIdToken(idToken, projectId) {
  if (!idToken) throw new HttpError(401, 'missing_id_token');
  let header;
  try {
    ({ header } = decodeJwt(idToken));
  } catch {
    throw new HttpError(401, 'invalid_id_token');
  }
  if (header.alg !== 'RS256' || !header.kid) {
    throw new HttpError(401, 'invalid_id_token');
  }
  const key = await googlePublicKey(header.kid);
  try {
    const payload = await verifyJwt(idToken, key, {
      alg: 'RS256',
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });
    if (typeof payload.sub !== 'string' || !payload.sub) throw new Error();
    if (typeof payload.auth_time === 'number' &&
        payload.auth_time > Math.floor(Date.now() / 1000) + 60) {
      throw new Error();
    }
    return payload;
  } catch {
    throw new HttpError(401, 'invalid_id_token');
  }
}

// ---------------------------------------------------------------------------
// Endpoint'ler
// ---------------------------------------------------------------------------

/** Umbra çağırır: kullanıcı "İzin ver" dedi → tek kullanımlık kısa ömürlü code. */
async function handleApprove(request, env) {
  const auth = request.headers.get('authorization') || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
  const user = await verifyFirebaseIdToken(idToken, env.FIREBASE_PROJECT_ID);

  // Sadece gerçek Umbra oturumu onay verebilir. LitList'in (custom token ile
  // açılmış) oturumu başka bir uygulamaya onay veremez.
  if (user.app || user.firebase?.sign_in_provider === 'custom') {
    throw new HttpError(403, 'only_umbra_can_approve');
  }
  if (user.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpError(403, 'anonymous_not_allowed');
  }

  const body = await readJson(request);
  const app = body.app;
  const challenge = body.challenge;
  const scopes = body.scopes ?? [];

  const allowed = typeof app === 'string' ? appScopes(env).get(app) : undefined;
  if (typeof app !== 'string' || !APP_RE.test(app) || !allowed) {
    throw new HttpError(400, 'unknown_app');
  }
  if (typeof challenge !== 'string' || !CHALLENGE_RE.test(challenge)) {
    throw new HttpError(400, 'invalid_challenge');
  }
  if (
    !Array.isArray(scopes) ||
    scopes.length > 20 ||
    !scopes.every((s) => typeof s === 'string' && s.length <= 48 && SCOPE_RE.test(s))
  ) {
    throw new HttpError(400, 'invalid_scopes');
  }
  // Umbra'nın izin ekranı zaten süzer; Worker da uygulamanın alabileceğinden fazlasını imzalamaz.
  if (scopes.length === 0 || !scopes.every((s) => allowed.has(s))) {
    throw new HttpError(403, 'scope_not_allowed');
  }

  const now = nowSeconds();
  const code = await signJwt(
    {
      sub: user.sub,
      aud: CODE_AUDIENCE,
      app,
      ch: challenge,
      scp: scopes,
      iat: now,
      exp: now + CODE_TTL_SECONDS,
      jti: crypto.randomUUID(),
    },
    await codeKey(env),
    'HS256',
  );

  return json(200, { code, expires_in: CODE_TTL_SECONDS });
}

/** LitList çağırır: code + verifier → Firebase custom token. */
async function handleToken(request, env) {
  const body = await readJson(request);
  const { code, verifier, app } = body;

  if (typeof code !== 'string' || code.length > 2048) {
    throw new HttpError(400, 'invalid_code');
  }
  if (typeof verifier !== 'string' || !VERIFIER_RE.test(verifier)) {
    throw new HttpError(400, 'invalid_verifier');
  }

  let payload;
  try {
    payload = await verifyJwt(code, await codeKey(env), {
      alg: 'HS256',
      audience: CODE_AUDIENCE,
      leeway: 0,
    });
  } catch {
    throw new HttpError(400, 'invalid_or_expired_code');
  }

  if (app !== undefined && app !== payload.app) {
    throw new HttpError(400, 'app_mismatch');
  }
  if (!appScopes(env).has(payload.app)) {
    throw new HttpError(400, 'unknown_app');
  }

  const challenge = await sha256Base64url(verifier);
  if (!safeEqual(challenge, payload.ch)) {
    throw new HttpError(400, 'verifier_mismatch');
  }

  // Firebase custom token formatı:
  // https://firebase.google.com/docs/auth/admin/create-custom-tokens#create_custom_tokens_using_a_third-party_jwt_library
  const now = nowSeconds();
  const token = await signJwt(
    {
      iss: env.FIREBASE_CLIENT_EMAIL,
      sub: env.FIREBASE_CLIENT_EMAIL,
      aud: CUSTOM_TOKEN_AUDIENCE,
      iat: now,
      exp: now + 3600,
      uid: payload.sub,
      claims: { app: payload.app, scopes: payload.scp ?? [] },
    },
    await firebasePrivateKey(env),
    'RS256',
  );

  return json(200, { token, uid: payload.sub });
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    try {
      if (pathname === '/health') {
        return json(200, { ok: true });
      }
      if (request.method !== 'POST') {
        throw new HttpError(405, 'method_not_allowed');
      }
      requireEnv(env);
      if (pathname === '/approve') return await handleApprove(request, env);
      if (pathname === '/token') return await handleToken(request, env);
      throw new HttpError(404, 'not_found');
    } catch (err) {
      if (err instanceof HttpError) {
        return json(err.status, { error: err.code });
      }
      console.error(err);
      return json(500, { error: 'internal_error' });
    }
  },
};
