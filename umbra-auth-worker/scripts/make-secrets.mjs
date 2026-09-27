// Kullanım:  node scripts/make-secrets.mjs "C:\\Users\\Oraz\\Downloads\\umbra-a97d8-firebase-adminsdk-xxxx.json"
// Firebase'den indirilen service account dosyasından .secrets.json üretir.
// Sonra:  npx wrangler secret bulk .secrets.json   ve ardından .secrets.json dosyasını SİL.
import { readFileSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';

const file = process.argv[2];
if (!file) {
  console.error('Service account JSON dosyasının yolunu ver.');
  process.exit(1);
}
const sa = JSON.parse(readFileSync(file, 'utf8'));
if (!sa.client_email || !sa.private_key) {
  console.error('Bu dosya bir service account anahtarı değil (client_email / private_key yok).');
  process.exit(1);
}
const secrets = {
  FIREBASE_CLIENT_EMAIL: sa.client_email,
  FIREBASE_PRIVATE_KEY: sa.private_key,
  CODE_SECRET: randomBytes(48).toString('base64url'),
};
writeFileSync('.secrets.json', JSON.stringify(secrets, null, 2));
// Yerel test (wrangler dev) için de .dev.vars yaz.
writeFileSync(
  '.dev.vars',
  Object.entries(secrets)
    .map(([k, v]) => `${k}=${JSON.stringify(v)}`)
    .join('\n') + '\n',
);
console.log(`Proje: ${sa.project_id}`);
console.log('.secrets.json ve .dev.vars oluşturuldu.');
console.log('Şimdi çalıştır:  npx wrangler secret bulk .secrets.json');
console.log('Sonra .secrets.json dosyasını sil.');
