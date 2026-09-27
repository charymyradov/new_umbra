/**
 * Küçük JWT yardımcıları — sadece WebCrypto (Cloudflare Workers yerleşik).
 * RS256 (Google/Firebase) ve HS256 (Worker'ın kendi code'ları) desteklenir.
 */

const RSA = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };
const HMAC = { name: 'HMAC', hash: 'SHA-256' };
const enc = new TextEncoder();
const dec = new TextDecoder();

export function b64urlEncode(bytes) {
  let s = '';
  for (const b of new Uint8Array(bytes)) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function b64urlDecode(text) {
  const b64 = text.replace(/-/g, '+').replace(/_/g, '/');
  const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
  const bin = atob(padded);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

const jsonPart = (obj) => b64urlEncode(enc.encode(JSON.stringify(obj)));

export class JwtError extends Error {}

/** JWT'yi imza kontrolü yapmadan parçalar. */
export function decodeJwt(token) {
  if (typeof token !== 'string') throw new JwtError('not_a_string');
  const parts = token.split('.');
  if (parts.length !== 3) throw new JwtError('malformed');
  try {
    return {
      header: JSON.parse(dec.decode(b64urlDecode(parts[0]))),
      payload: JSON.parse(dec.decode(b64urlDecode(parts[1]))),
      signingInput: enc.encode(`${parts[0]}.${parts[1]}`),
      signature: b64urlDecode(parts[2]),
    };
  } catch {
    throw new JwtError('malformed');
  }
}

export async function importRsaPrivateKey(pem) {
  const body = pem
    .replace(/\\n/g, '\n')
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey('pkcs8', der, RSA, false, ['sign']);
}

export function importRsaPublicJwk(jwk) {
  const { kty, n, e } = jwk;
  return crypto.subtle.importKey('jwk', { kty, n, e, ext: true }, RSA, false, [
    'verify',
  ]);
}

export function importHmacKey(secret) {
  return crypto.subtle.importKey('raw', enc.encode(secret), HMAC, false, [
    'sign',
    'verify',
  ]);
}

export async function signJwt(payload, key, alg) {
  const header = { alg, typ: 'JWT' };
  const input = `${jsonPart(header)}.${jsonPart(payload)}`;
  const algo = alg === 'RS256' ? RSA : HMAC;
  const sig = await crypto.subtle.sign(algo, key, enc.encode(input));
  return `${input}.${b64urlEncode(sig)}`;
}

/**
 * İmzayı ve zaman alanlarını doğrular, payload'ı döner.
 * @param {{alg:string, issuer?:string, audience?:string, leeway?:number}} opts
 */
export async function verifyJwt(token, key, opts) {
  const { header, payload, signingInput, signature } = decodeJwt(token);
  if (header.alg !== opts.alg) throw new JwtError('wrong_alg');
  const algo = opts.alg === 'RS256' ? RSA : HMAC;
  const ok = await crypto.subtle.verify(algo, key, signature, signingInput);
  if (!ok) throw new JwtError('bad_signature');

  const now = Math.floor(Date.now() / 1000);
  const leeway = opts.leeway ?? 5;
  if (typeof payload.exp !== 'number' || payload.exp + leeway <= now) {
    throw new JwtError('expired');
  }
  if (typeof payload.iat === 'number' && payload.iat - leeway > now) {
    throw new JwtError('issued_in_future');
  }
  if (typeof payload.nbf === 'number' && payload.nbf - leeway > now) {
    throw new JwtError('not_yet_valid');
  }
  if (opts.issuer !== undefined && payload.iss !== opts.issuer) {
    throw new JwtError('wrong_issuer');
  }
  if (opts.audience !== undefined) {
    const aud = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    if (!aud.includes(opts.audience)) throw new JwtError('wrong_audience');
  }
  return payload;
}
