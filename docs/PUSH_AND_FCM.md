# Push / FCM (Flutter)

## Status

- Flutter registers device tokens via the Laravel `DeviceToken` APIs.
- In-app notification inbox + print notices work without FCM.
- **Production FCM HTTP v1 on the API is optional.**

If `FCM_SERVICE_ACCOUNT_JSON` is empty on the VPS, the backend sends **in-app + Reverb** notifications only (no APNs/FCM push). That is an accepted production mode until the Firebase service account is uploaded.

## Ops checklist (API)

See `Musamimuk 3/docs/LEFTOVER-AFTER-REVERB-DEPLOY.md`:

1. Upload Firebase service-account JSON to the VPS (outside the web root).
2. Set `FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT_JSON` in production `.env`.
3. `php artisan config:cache`.
4. iOS also needs APNs key in Firebase for remote push.

## App Store / Play

Until FCM+APNs are configured, do not market “push alerts” as guaranteed; in-app + realtime sockets remain the primary path.
