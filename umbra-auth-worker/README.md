# umbra-auth — "Umbra ile devam et" token sunucusu (Cloudflare Workers)

LitList'in, kullanıcının Umbra hesabıyla (aynı Firebase UID) şifresiz ve tek dokunuşla
oturum açmasını sağlar. Firebase ücretsiz (Spark) planda kalır; bu Worker da
Cloudflare'in ücretsiz planında çalışır. Hiçbir npm kütüphanesi kullanmaz.

## Kurulum (Windows, bir kez)

> Önce `node -v` yaz. Hata verirse https://nodejs.org adresinden **LTS** sürümünü kur.

1. Terminali bu klasörde aç:
   ```
   cd C:\Users\Oraz\Desktop\new\umbra-auth-worker
   npm install
   ```
2. Cloudflare'e bağlan (tarayıcı açılır, **Allow** de):
   ```
   npx wrangler login
   ```
3. Worker'ı yayınla:
   ```
   npm run deploy
   ```
   İlk seferde `workers.dev` alt alan adı seçmeni isteyebilir (ör. `oraz`).
   Sonunda şöyle bir adres verir: `https://umbra-auth.oraz.workers.dev` — bunu not al.
4. Firebase gizli anahtarını al:
   Firebase Console → ⚙ **Project settings** → **Service accounts** →
   **Generate new private key** → JSON dosyası iner (ör. `Downloads` klasörüne).
   **Bu dosyayı kimseyle paylaşma, uygulamaya ve git'e koyma.**
5. Anahtarı Worker'a gizli değişken olarak yükle:
   ```
   npm run secrets -- "C:\Users\Oraz\Downloads\umbra-a97d8-firebase-adminsdk-XXXX.json"
   npx wrangler secret bulk .secrets.json
   del .secrets.json
   ```
6. Test et: tarayıcıda `https://umbra-auth.<senin-adın>.workers.dev/health` aç →
   `{"ok":true}` görmelisin.

İndirdiğin JSON dosyasını güvenli bir yere taşı ya da sil. Anahtar sızarsa:
Firebase Console → Service accounts → Google Cloud'da anahtarı sil, yenisini üret, 5. adımı tekrarla.

## Endpoint'ler

| Kim çağırır | İstek | Cevap |
|---|---|---|
| Umbra ("İzin ver" sonrası) | `POST /approve`  başlık: `Authorization: Bearer <Firebase ID token>`  gövde: `{"app":"litlist","challenge":"...","scopes":["identity.name","reading.profile"]}` | `{"code":"...","expires_in":60}` |
| LitList (geri dönünce) | `POST /token`  gövde: `{"app":"litlist","code":"...","verifier":"..."}` | `{"token":"<custom token>","uid":"..."}` → `signInWithCustomToken(token)` |

- `verifier`: LitList'in ürettiği 43–128 karakterlik rastgele base64url metin.
- `challenge = base64url(sha256(verifier))` (43 karakter).
- `code` 60 saniye geçerlidir ve sadece doğru `verifier` ile kullanılabilir.
- LitList'in oturumunda `request.auth.token.app == "litlist"` ve
  `request.auth.token.scopes` bulunur — Firestore kuralları bunu kullanır.
- LitList oturumu (`app` etiketi olan) başka bir uygulamaya onay **veremez**.

## Scope kontrolü

`wrangler.toml` → `[vars.APP_SCOPES]` her uygulamanın isteyebileceği scope'ları listeler.
Listede olmayan bir scope istenirse `/approve` **403 `scope_not_allowed`** döner. Umbra'nın izin
ekranı zaten süzer; bu, Worker'ın da fazlasını imzalamamasını sağlar.

## Yeni uygulama eklemek

1. `wrangler.toml` → `[vars.APP_SCOPES]` altına `yeniuygulama = ["identity.name", ...]` ekle.
2. Umbra'da `lib/data/connect/external_apps.dart` → `kExternalApps` içine aynı uygulamayı
   (ad, callback adresi, `allowedScopes`) ekle. İki liste aynı olmalı.
3. `npm test` → `npm run deploy`.

## Yerel test

```
npm test          # internet gerektirmeyen uçtan uca akış testi
npm run dev       # .dev.vars ile yerelde çalıştırır (npm run secrets bunu da üretir)
```
