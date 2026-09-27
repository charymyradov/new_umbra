# Umbra

A portable memory of you, that you can see and control — Flutter port of the
"Umbra v5" HTML prototype.

## Run

```bash
flutter pub get
flutter run
```

Tap **Explore the demo account** on the first screen to open a fully seeded account (Maya),
or create a local account and go through onboarding.

## Architecture — MVVM with Riverpod

```
lib/
  main.dart                 ProviderScope + SharedPreferences override, font warm-up
  app/app.dart              MaterialApp, lifecycle (flush / day rollover), root screen switch
  core/                     theme + format helpers (no state)
  data/                     MODEL — immutable records and I/O
    models.dart               Memory, Pending, LogEntry, QuizItem, AccountData (copyWith + JSON)
    catalog.dart              layers, sources, apps, domains, quizzes, games
    seed.dart                 demo account content
    repositories/             AuthRepository (salted SHA-256), AccountRepository (JSON per account)
    services/share_service.dart
  domain/                   pure rules: permissions/expiry (rules.dart), today's plan, export
  state/                    app-wide state (Riverpod)
    session_controller.dart   who is signed in
    account_controller.dart   the account + every rule that changes it, debounced saving
    toast_controller.dart     toasts with Undo
    providers.dart            prefs, clock, repositories, screenProvider, planProvider, pendingVisibleProvider
  features/<screen>/        VIEWMODEL + VIEW per screen
    *_view_model.dart         Notifier<ImmutableState>: derives view state, exposes commands
    *_view.dart / *_sheet.dart ConsumerWidgets: render state, call commands, no business logic
  widgets/                  reusable, state-free UI (icons, rings, pills, toast layer)
```

Rules of the road:

- **Views** only `ref.watch(xViewModelProvider)` and call `ref.read(xViewModelProvider.notifier).command()`.
  Text controllers, drag offsets and other pure gesture state stay in the widget.
- **ViewModels** turn `AccountData` into screen-ready state (labels, counts, flags) and forward intents
  to `AccountController`. Screen-local UI state (open sections, filters) lives in the ViewModel; for the
  kept-alive ones (Today, Memory) it sits on a session-scoped provider so it resets per account.
- **AccountController** is the single writer of account data. Every change is immutable
  (`state = state.copyWith(...)`), logged, and saved 250 ms later; `flush()` runs on sign-out/background.
- **Derived providers** (`planProvider`, `pendingVisibleProvider`, `screenProvider`) are memoised by Riverpod
  and recompute only when the account changes.
- Everything injectable is a provider (`sharedPreferencesProvider`, `clockProvider`, `shareServiceProvider`),
  so tests run against a `ProviderContainer` with overrides.

### Behaviour

- **Local-first accounts.** Accounts (salted SHA-256 passwords) and each account's data live in
  `shared_preferences`; changes are saved 250 ms after they happen and flushed when the app is backgrounded.
- **Memory layers.** Identity (edits need a review step), Preferences ("still true?" after 60 days),
  Patterns (confidence dots), Live (auto-deleted after 7 days).
- **Consent.** Anything inferred waits in "Is this you?" until kept, edited or rejected. Turning a learning
  source or connected app off hides its memories and signals immediately.
- **Undo.** Every destructive action (forget, forget layer/source/everything, disconnect) can be undone from the toast.
- **Daily rollover.** Check-in and today's plan reset each day; the streak continues only on consecutive days.
- **Export.** JSON (`umbra.memory/v1`) and a plain-text summary through the system share sheet
  (falls back to the clipboard where sharing isn't available). Health items are excluded unless enabled.

### Performance notes

- Fonts (Newsreader, Public Sans, Fredoka) are bundled in `assets/fonts` and pre-loaded at start-up:
  no network fetch, no fallback-font flash.
- Icons are cached SVGs tinted with a color filter, so color animations never re-parse SVG.
- Rings, donuts, the sun arc and dashed outlines are `CustomPainter`s instead of layered widgets.
- No `BackdropFilter`; the plan is a memoised provider; toasts are their own provider, so showing one
  doesn't rebuild the screen; `select` keeps the root from rebuilding on unrelated changes.

## Tests

```bash
flutter test
```

- `test/widget_test.dart` — model + ViewModel tests on a `ProviderContainer`: sign-up/sign-in/persistence,
  forget + undo, keeping a pending item, check-in and streak, permission filtering, UI-state reset per account.
- `test/screens_test.dart` — every tab rendered at 390 px and 340 px, memory sheet, and a full quiz run.
