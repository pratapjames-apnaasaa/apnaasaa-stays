# ApnaaSaa Stays (`unite_india_app`)

**Trusted stays for LGBTQIA+ in India** — Flutter + Firebase (Auth, Firestore) pilot.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_BROWSER_KEY
flutter run             # device (Maps key optional; set same define if you use HTTP geocoding)
```

The **same** Google Cloud API key is used for:

- Injecting the Maps JavaScript API on **web** (`lib/platform/load_google_maps_web.dart`)
- The HTTP Geocoding fallback in host onboarding (`GOOGLE_MAPS_API_KEY` via `--dart-define`)

Enable **Maps JavaScript API** and **Geocoding API** for that key. Restrict the key by HTTP referrer (web) in Google Cloud Console.

If you omit `GOOGLE_MAPS_API_KEY`, the app still runs but maps/geocoding on web will be limited.

Configure Firebase with FlutterFire (`lib/firebase_options.dart`).

### Firebase Console

- **Authentication → Sign-in method:** enable **Phone** (for OTP) and **Anonymous** (for “Preview host setup without SMS”).

## App flow

- **Signed out:** Landing → choose *guest* or *host* → phone OTP (intent selects Browse vs Host tab after sign-in).
- **Signed in:** Bottom navigation — **Browse** (published listings) and **Host** (start or continue listing). Listings are stored under `hosts/{userId}` with `userId` and `listingStatus` (`draft` / `published`).
- **Preview host (no SMS):** Signs in **anonymously**, opens the host onboarding wizard; listing doc id = Firebase `uid` (same rules as phone users).

## Firestore rules

Rules are in **`firestore.rules`** (auth + published reads + owner writes). Deploy:

```bash
firebase deploy --only firestore:rules
```

## CI / secrets

GitHub Actions runs `flutter pub get`, `analyze`, and `test`. Optional: add repository secret `GOOGLE_MAPS_API_KEY` and pass `--dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}` to `flutter test` / `flutter build web` if you want CI builds to include maps (not required for `analyze`).

## Legacy listings

Older pilot data may have been created with **random document IDs** (before `hosts/{userId}`). Those rows are not tied to a user account; re-publish from the host flow to migrate.
