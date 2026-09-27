// Uçtan uca akış testi (internet gerektirmez): sahte "Google" anahtarıyla
// Firebase ID token üretir, /approve ve /token'ı çağırır, çıkan custom
// token'ın Firebase formatına uyduğunu doğrular.
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { signJwt, verifyJwt, b64urlEncode, decodeJwt } from '../src/jwt.js';

const PROJECT = 'umbra-a97d8';
const RSA = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]) };

// "Google" (securetoken) anahtarı ve service account anahtarı
const google = await crypto.subtle.generateKey(RSA, true, ['sign', 'verify']);
const sa = await crypto.subtle.generateKey(RSA, true, ['sign', 'verify']);
const googleJwk = { ...(await crypto.subtle.exportKey('jwk', google.publicKey)), kid: 'k1', alg: 'RS256', use: 'sig' };
const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', sa.privateKey));
const pem = `-----BEGIN PRIVATE KEY-----\n${Buffer.from(pkcs8).toString('base64').match(/.{1,64}/g).join('\n')}\n-----END PRIVATE KEY-----\n`;

globalThis.fetch = async (url) => {
  assert.match(String(url), /securetoken@system\.gserviceaccount\.com/);
  return new Response(JSON.stringify({ keys: [googleJwk] }), { headers: { 'cache-control': 'public, max-age=100' } });
};

const env = {
  FIREBASE_PROJECT_ID: PROJECT,
  APP_SCOPES: { litlist: ['identity.name', 'reading.profile', 'memory.live'] },
  FIREBASE_CLIENT_EMAIL: 'firebase-adminsdk-x@umbra-a97d8.iam.gserviceaccount.com',
  FIREBASE_PRIVATE_KEY: pem.replace(/\n/g, '\\n'), // kaçışlı hali de çalışmalı
  CODE_SECRET: 'test-secret-that-is-long-enough-1234567890',
};

async function idToken(extra = {}, provider = 'password') {
  const now = Math.floor(Date.now() / 1000);
  const t = await signJwt({
    iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, sub: 'USER_U', user_id: 'USER_U',
    iat: now, exp: now + 3600, auth_time: now, firebase: { sign_in_provider: provider }, ...extra,
  }, google.privateKey, 'RS256');
  // kid'i başlığa ekle
  const [, p, s] = t.split('.');
  const h = b64urlEncode(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid: 'k1' })));
  const input = `${h}.${p}`;
  const sig = await crypto.subtle.sign(RSA, google.privateKey, new TextEncoder().encode(input));
  return `${input}.${b64urlEncode(sig)}`;
}

const call = (path, body, headers = {}) =>
  worker.fetch(new Request(`https://w.example${path}`, {
    method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body),
  }), env);

const verifier = b64urlEncode(crypto.getRandomValues(new Uint8Array(32)));
const challenge = b64urlEncode(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier)));

// health
assert.equal((await worker.fetch(new Request('https://w.example/health'), env)).status, 200);

// 1) approve — geçerli Umbra oturumu
let res = await call('/approve', { app: 'litlist', challenge, scopes: ['identity.name', 'reading.profile'] }, { authorization: `Bearer ${await idToken()}` });
assert.equal(res.status, 200, await res.clone().text());
const { code } = await res.json();

// 2) token — doğru verifier
res = await call('/token', { app: 'litlist', code, verifier });
assert.equal(res.status, 200, await res.clone().text());
const { token, uid } = await res.json();
assert.equal(uid, 'USER_U');

// custom token Firebase formatında mı?
const payload = await verifyJwt(token, sa.publicKey, {
  alg: 'RS256', issuer: env.FIREBASE_CLIENT_EMAIL,
  audience: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
});
assert.equal(payload.sub, env.FIREBASE_CLIENT_EMAIL);
assert.equal(payload.uid, 'USER_U');
assert.deepEqual(payload.claims, { app: 'litlist', scopes: ['identity.name', 'reading.profile'] });
assert.ok(payload.exp - payload.iat <= 3600);
assert.equal(decodeJwt(token).header.alg, 'RS256');

// Negatif durumlar
const expect = async (p, status, error) => { const r = await p; const b = await r.json(); assert.equal(r.status, status, JSON.stringify(b)); assert.equal(b.error, error); };
await expect(call('/token', { app: 'litlist', code, verifier: b64urlEncode(crypto.getRandomValues(new Uint8Array(32))) }), 400, 'verifier_mismatch');
await expect(call('/token', { app: 'other', code, verifier }), 400, 'app_mismatch');
await expect(call('/token', { app: 'litlist', code: code.slice(0, -2) + 'xx', verifier }), 400, 'invalid_or_expired_code');
await expect(call('/approve', { app: 'litlist', challenge }, {}), 401, 'missing_id_token');
await expect(call('/approve', { app: 'evil', challenge }, { authorization: `Bearer ${await idToken()}` }), 400, 'unknown_app');
await expect(call('/approve', { app: 'litlist', challenge, scopes: ['identity.name'] }, { authorization: `Bearer ${await idToken({ app: 'litlist' }, 'custom')}` }), 403, 'only_umbra_can_approve');
await expect(call('/approve', { app: 'litlist', challenge, scopes: ['identity.name', 'memory.everything'] }, { authorization: `Bearer ${await idToken()}` }), 403, 'scope_not_allowed');
await expect(call('/approve', { app: 'litlist', challenge, scopes: [] }, { authorization: `Bearer ${await idToken()}` }), 403, 'scope_not_allowed');
await expect(call('/approve', { app: 'litlist', challenge }, { authorization: `Bearer ${await idToken({ aud: 'other-project' })}` }), 401, 'invalid_id_token');
const now = Math.floor(Date.now() / 1000);
await expect(call('/approve', { app: 'litlist', challenge }, { authorization: `Bearer ${await idToken({ exp: now - 100, iat: now - 4000 })}` }), 401, 'invalid_id_token');
await expect(call('/approve', { app: 'litlist', challenge: 'short', scopes: ['identity.name'] }, { authorization: `Bearer ${await idToken()}` }), 400, 'invalid_challenge');
// JSON metni olarak verilen APP_SCOPES da çalışır.
const envString = { ...env, APP_SCOPES: JSON.stringify(env.APP_SCOPES) };
const r2 = await worker.fetch(new Request('https://w.example/approve', { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${await idToken()}` }, body: JSON.stringify({ app: 'litlist', challenge, scopes: ['memory.live'] }) }), envString);
assert.equal(r2.status, 200, await r2.clone().text());

// Süresi dolmuş code
const expiredCode = await signJwt({ sub: 'USER_U', aud: 'umbra-auth-code', app: 'litlist', ch: challenge, scp: [], iat: now - 120, exp: now - 60 },
  await crypto.subtle.importKey('raw', new TextEncoder().encode(env.CODE_SECRET), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']), 'HS256');
await expect(call('/token', { app: 'litlist', code: expiredCode, verifier }), 400, 'invalid_or_expired_code');

console.log('Tüm testler geçti ✔');
