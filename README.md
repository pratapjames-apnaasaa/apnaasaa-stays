# ApnaaSaa Stays (`unite_india_app`)

**Trusted stays for LGBTQIA+ in India** — Flutter + Firebase (Auth, Firestore) pilot.

## Run

```bash
flutter pub get
flutter run -d chrome   # web
flutter run             # device
```

Configure Firebase with FlutterFire (`lib/firebase_options.dart`). For Google Maps on web, set your Maps JavaScript API key in `web/index.html` and keep the HTTP geocoding fallback key in sync (see `host_onboarding_page.dart`).

## App flow

- **Signed out:** Landing → choose *guest* or *host* → phone OTP (intent selects Browse vs Host tab after sign-in).
- **Signed in:** Bottom navigation — **Browse** (published listings) and **Host** (start or continue listing). Listings are stored under `hosts/{userId}` with `userId` and `listingStatus` (`draft` / `published`).
- **Preview host (no SMS):** From the landing page — uses doc id `preview-web-user` (no Firebase Auth).

## Firestore rules

Example rules for auth + published reads are in **`firestore.rules`**. Deploy with:

```bash
firebase deploy --only firestore:rules
```

Tune rules before production (especially preview / demo exceptions).

## CI

GitHub Actions runs `flutter pub get`, `analyze`, and `test`.

## Legacy listings

Older pilot data may have been created with **random document IDs** (before `hosts/{userId}`). Those rows are not tied to a user account; re-publish from the host flow to migrate.
