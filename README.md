# YourLeague

Tournament manager & shop (Flutter + Firebase + Stripe + Node).

## Stripe / Payments (Android Focus)
The app uses the Stripe PaymentSheet via the `flutter_stripe` package.

Flow:
1. Health check to backend (`GET /health`).
2. Create PaymentIntent (`POST /create-payment-intent`).
3. Initialize PaymentSheet with returned `clientSecret`.
4. Present PaymentSheet.

If the server is unreachable you will now get a friendly SnackBar instead of an app crash.

### Local Development Options
Choose ONE of these in `ApiConfig`:

| Scenario | Settings | Notes |
|----------|----------|-------|
| Android emulator | `useEmulator = true` | Backend must run on your PC, use `10.0.2.2` mapping. |
| Physical device same WiFi | `useEmulator = false`, `useNgrok = false`, set `localIP` | Add your PC IPv4 from `ipconfig`. |
| Remote tester / outside LAN | `useNgrok = true` and set `ngrokUrl` | Must be https (Stripe requires secure origin for some features). |

After changing flags, hot restart the app so `baseUrl` recalculates.

### Ngrok Setup
1. Run your Node server locally: `node server/index.js`.
2. Start ngrok: `ngrok http 3000` (or `ngrok http --domain=<reserved> 3000`).
3. Copy the https URL and put in `ApiConfig.ngrokUrl` and set `useNgrok = true`.
4. (Optional) Add domain to `network_security_config.xml` if you ever use http (prefer https so no change needed).

### Amount Handling
Stripe expects the amount in the smallest currency unit (e.g. cents). We convert in `CartPage` with:
```dart
final totalAmount = (cartCubit.totalAmount * 100).toInt().toString();
```

### Common Android Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| Lost connection to device after tapping checkout | Uncaught exception from backend timeout | Added health check & granular error handling (update to latest code). |
| PaymentSheet shows blank / fails | Wrong publishable key | Confirm `StripeConfig.publishableKey` is test key from Stripe dashboard. |
| Network errors on physical device | Wrong `localIP` or server not on same WiFi | Update `ApiConfig.localIP`, verify ping, or switch to ngrok. |

## Security (Action Needed)
Do NOT commit live secrets.
- Move Stripe secret key in `server/index.js` to `process.env.STRIPE_SECRET_KEY`.
- Move Gmail credentials to env (`process.env.GMAIL_USER` / `process.env.GMAIL_PASS`). Use an App Password.
- Create a `.env` and load via `dotenv`:
```js
require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
```
Add `.env` to `.gitignore`.

## Testing Payment Flow
1. Start backend: `node server/index.js`.
2. Ensure app flags correct (see table above).
3. Add items to cart.
4. Tap Checkout → PaymentSheet appears.
5. Use Stripe test card: `4242 4242 4242 4242`, any future expiry, any CVC.
6. Success SnackBar should appear and cart clears.
7. Failure scenarios: stop backend then try checkout → you should see a red SnackBar with a helpful message.

## Future Improvements
- Add retry button on network failure.
- Switch server to return structured error codes.
- Add Google/Apple Pay (requires extra configuration in PaymentSheet params).
- Video uploads & match notifications now available:
	- POST /matches/:matchId/videos (multipart field: video, optional title)
	- GET  /matches/:matchId/videos
	- POST /matches/:matchId/notify (JSON: recipients[], subject?, message?)
	- PUSH: POST /matches/:matchId/push (JSON: title, body) → sends FCM to topic `match_<id>`
	- Client push service: `MatchPushService` (subscribe/unsubscribe and trigger push)

## Push Notifications (FCM)
We use Firebase Cloud Messaging (FCM) for match push notifications.

Server setup:
1. Create a Firebase service account in Firebase Console → Project Settings → Service Accounts.
2. Download JSON and save as `server/serviceAccountKey.json` (not committed).
3. Start server; you should see "Firebase Admin initialized for FCM".

Endpoints:
- Subscribe/unsubscribe is done on client topics: `match_<matchId>`
- Send: `POST /matches/:matchId/push` with body `{ "title": "...", "body": "..." }`

Client (Flutter):
- `MatchPushService.subscribeToMatch(matchId)` / `.unsubscribeFromMatch(matchId)`
- UI: Match Events page menu → subscribe/unsubscribe and send push.

Notes:
- Ensure `firebase_messaging` is installed; Android 13+ requires the POST_NOTIFICATIONS permission (already enabled).
- For background display, you can integrate a background handler to show a local notification using `flutter_local_notifications`.
	- Client services: `VideoService` & `MatchNotificationService` in `lib/User/services/`.

## Development Resources
- [Flutter Docs](https://docs.flutter.dev/)
- [Stripe Flutter Docs](https://pub.dev/packages/flutter_stripe)
- [Stripe PaymentIntents](https://stripe.com/docs/payments/payment-intents)

