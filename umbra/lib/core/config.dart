/// Deployment settings for the Firebase project and the auth worker.
library;

/// The Firestore database in project `umbra-a97d8` is a named database called
/// `default` (not the implicit `(default)`), so it must be named explicitly.
const firestoreDatabaseId = 'default';

/// "Continue with Umbra" token server (Cloudflare Worker, `umbra-auth-worker`).
const authWorkerUrl = 'https://umbra-auth.oraz-umbra.workers.dev';
