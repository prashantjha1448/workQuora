# WorkQuora Client App — Flutter (Phase 1)

Client-side app ("wQ Recruit", indigo theme) for the WorkQuora marketplace.
This phase covers project foundation, auth (matching `authController.js`
exactly), and the design-token theme system from `DESIGN.md`.

## Architecture

Clean Architecture, feature-first:

```
lib/
  core/
    theme/        -> design tokens (colors, typography, spacing) + ThemeData
    network/       -> Dio client w/ token refresh, endpoint constants
    storage/       -> secure storage (tokens) + Hive (offline cache)
    router/         -> go_router with auth-aware redirects
    error/          -> typed AppFailure
  features/
    auth/
      data/         -> models, remote datasource, repository impl
      domain/       -> repository interface
      application/  -> Riverpod controllers (state)
      presentation/ -> screens + widgets
  shared/           -> cross-feature reusable widgets
```

## Why these choices (scale: 10M users)

- **Riverpod** over Bloc/Provider: compile-safe DI, automatic disposal,
  `select`-based granular rebuilds — fewer wasted widget rebuilds at scale.
- **Single-flight token refresh** in `ApiClient`: if many requests 401 at
  once (token just expired), only ONE `/auth/refresh` call fires — protects
  the auth service from a thundering-herd retry storm.
- **Secure storage for tokens, Hive for cache**: tokens never touch
  plaintext storage; Hive (binary, fast) caches non-sensitive lists/profiles
  for offline-first + reduces redundant network calls (battery + data).
- **google_fonts caches Inter locally** after first load — no repeated
  downloads across app restarts.
- **Text scale clamping** in `app.dart` keeps the premium layout intact
  across device accessibility settings without ignoring user preference
  entirely.

## Backend contract

Endpoints in `core/network/api_endpoints.dart` map 1:1 to
`authRoutes.js`. Response shapes match `sendTokenResponse()` in
`authController.js` exactly: `{ success, token, refreshToken, user, data }`.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

## Next phases (not yet built)

- Notifications (push + in-app)
- Performance pass: integration_test golden tests, DevTools memory profiling,
  `flutter build appbundle --analyze-size`

## Phase 2 — Discover (done)

Screens: bottom-nav shell (Home/Discover/Post/Messages/Profile) using
`StatefulShellRoute.indexedStack` — each tab keeps its own state/scroll
position without rebuilding when you switch tabs (cheaper than recreating
widgets every time).

Discover screen: debounced search (400ms), category chips, geolocation via
`geolocator`, offline-first Hive cache fallback per (category, keyword) key,
shimmer loading skeletons, lazy `SliverList.separated` rendering, image
downscaling on avatars (`memCacheWidth/Height`) to cut decode memory.

**⚠️ Backend gap found:** `GET /geo/nearby-freelancers` (geoController.js)
has no `page`/`limit`/`skip` — it returns the entire matching result set in
one response (`User.find(query)` with no `.limit()`). This phase mitigates
client-side (fetch once, reveal in batches of 10 on scroll), but at 10M
users this endpoint needs real backend pagination + likely a proper search
index (Atlas Search / Elasticsearch) before it's safe in production. `GET
/geo/nearby-jobs` does have `.limit(50)` but still no `skip`/cursor.

## Phase 3 — Talent Profile (done)

`GET /profile/user/:userId` (public) + `GET /reviews/:userId` fetched in
parallel via `talentProfileProvider` (`FutureProvider.autoDispose.family`) —
each visited profile is cached independently, and auto-disposed shortly
after the screen is popped so browsing 50 profiles in a session doesn't
leak 50 cached objects in memory.

Screen: collapsible `SliverAppBar` header, stat block (rating/completed/
success-rate/response-time — all from `getPublicProfile`'s `stats` +
performance fields), bio, skills, reviews list, sticky bottom action bar.

**Message button is intentionally not wired to open a chat.** Backend's
`sendMessage` (messageController.js) requires a `jobId` — there's no
profile-to-profile DM without a job context. Tapping it explains this
instead of pretending to work. Hire routes to the (not-yet-built) Post Job
flow.

## Phase 4 — Post a Job (done)

`POST /jobs` (jobController.createJob). Key backend behavior this phase
respects exactly:

- **KYC is enforced server-side inside the controller**, not via route
  middleware — `createJob` manually checks `Kyc.aadhaarVerified &&
  Kyc.panVerified` and returns a 400 if not satisfied. The app adds a
  **soft client-side gate** using `currentUser.kycVerified` (from `/auth/me`)
  so an unverified client never wastes time filling a 4-step form, but the
  real enforcement stays server-side where it belongs. If the 400 still
  comes back with a KYC-related message, the repository tags it
  (`statusCode: 428`, client-side-only convention) so the UI could special-case
  it further later.
- `location.coordinates` is **`[longitude, latitude]`** order, not lat/lng —
  easy to get backwards; the datasource comments this explicitly.

4-step form (Basics → Details → Budget → Review) with per-step validation
gating the Continue button, animated step transitions, success screen.
Reuses the Discover category list as the single source of truth for job
categories. Reuses `LocationService` from Phase 2 for "Use my current
location" instead of duplicating geolocation logic.

**A real bug caught and fixed during this build, not just shipped**: the
form fields initially recreated their `TextEditingController` on every
Riverpod rebuild (a common mistake), which causes the text cursor to jump
to the end on every keystroke once external state changes trigger a
rebuild — feels broken, defeats the "smooth premium" goal. Fixed by moving
`title`/`description`/`address` controllers into `ConsumerStatefulWidget`
state so they're created once and persist across rebuilds.

## Phase 5 — Messages (done)

REST: `GET /messages/conversations` (list) + `GET /messages/:jobId/:otherUserId`
(history, also server-side marks-as-read). Socket.io for live send/receive,
typing indicators, delivered/read receipts — matching `chatSocket.js` +
the auth handshake in `server.js` (`socket.handshake.auth.token`, websocket
transport only, no polling fallback).

**Room semantics — traced from the server's emit logic, not the inline
comment.** `chatSocket.js` says `join_room` is `"format: jobId_otherUserId"`,
but tracing what `sendMessage`/`send_message` actually emit to shows the
room you should join is `${jobId}_${yourOwnUserId}`, not the other party's
id — emitting `roomId = jobId_receiverId` only resolves to "the room a user
joined for themselves" if that user is the receiver. Documented this in
`ChatSocketService`'s doc comment so the next person doesn't have to
re-trace it. `typing_status` follows the opposite addressing (target the
other user's room), confirmed against the same emit logic.

**Battery/connection discipline** (the explicit ask from the start of this
build): `ChatSocketService` is never auto-connected. `ChatController`
(`AutoDisposeFamilyNotifier`, keyed by `(jobId, otherUserId)`) connects on
`build()` and disconnects in `ref.onDispose` — so the socket exists only
while a chat screen is actually mounted, and Riverpod's autoDispose tears
it down the moment you navigate away. The Conversations list screen never
opens a socket at all; it's REST + pull-to-refresh only, since live unread
badges aren't worth a background connection.

**Optimistic send**: a locally-created message (temp id, `isOptimistic:
true`) renders immediately with a clock icon; once the server's
`receive_message` echo arrives it's matched by sender+text and swapped for
the real persisted message (real id, tick status) — duplicate-safe by id
before that swap logic even runs.

Typing indicator emission is debounced to fire on typing *pauses* (1.5s),
not every keystroke — same keystroke-vs-pause discipline as Discover's
search box in Phase 2, this time saving socket messages instead of HTTP
calls.



## Phase 6 — Wallet & Payments (done)

`GET /wallet/balance`, `GET /wallet/transactions` (genuinely paginated —
`page`/`limit`/`skip` all implemented server-side, unlike Discover's gap),
`POST /wallet/bank-account`, and the Razorpay add-money round trip
(`POST /wallet/add-money/create-order` → native Razorpay checkout →
`POST /wallet/add-money/verify`).

**Rupee/paise discipline**: the client never converts between rupees and
paise itself — `formattedBalance` (rupees, for display) and `balance`
(paise, kept around but unused for math) both come pre-converted from the
server. Amounts sent up (add-money, withdraw) are always rupees; the server
does `Math.round(amount * 100)`. This mirrors the fix from the 100x
rupee/paise admin-credit bug documented in the project history — the
client-side rule here is simply: never multiply or divide by 100 in Dart.

**Withdrawal PIN**: there is no dedicated "set PIN" endpoint — it's set as
a side effect of `POST /kyc/bank/submit`'s optional `pin` field (see Phase
7). The Wallet screen itself doesn't expose a withdraw flow yet (most
clients deposit and pay rather than withdraw); `withdraw()` exists in the
repository layer ready for a future "Freelancer Earnings" screen.

`razorpay_flutter`'s event callbacks (`EVENT_PAYMENT_SUCCESS` etc.) are
synchronously typed, so `AddMoneyController` fires the async verification
call as fire-and-forget from inside the sync handler rather than trying to
make the handler itself `async`.

## Phase 7 — Profile & KYC (done)

`GET/PUT /profile/me` + `/profile/update` for the editable profile fields.
KYC is a 5-step flow (`mobile OTP → PAN → Aadhaar → Bank+PIN → Selfie`)
matching `kycController.js` exactly, including the **canonical
`aadhaarVerified` field** (never the legacy single-a `aadharVerified`
alias) — same fix pattern documented in this project's bug history.

`KycController` derives the current step from `GET /kyc/status`'s flags
rather than hardcoding step state — so re-opening the KYC screen after
closing it mid-flow resumes at the right step instead of restarting.
After each successful step, it also calls `AuthController.refreshUser()`
so the Post Job KYC gate (Phase 4) picks up the change immediately,
without requiring a logout/login.

Document capture uses `image_picker` (camera or gallery for PAN/Aadhaar/
bank docs, front camera only for the selfie) — images are compressed
client-side (`imageQuality`, `maxWidth`) before upload to keep multipart
payloads small on mobile data.

**Native permissions still need adding once `flutter create .` is run for
this project** (not included here since no native android/ios folders exist
yet in this scaffold):
- Android `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`, `INTERNET`
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- Razorpay Android: check `https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/` for current ProGuard/R8 exclusion rules before a release build — their native SDK setup steps can change between versions.



