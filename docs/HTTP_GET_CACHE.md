# HTTP GET cache (mobile)

Catalog and public GETs are cached on-device with a short TTL via `ApiCacheInterceptor` on `ApiClient`. Repositories do not implement their own response caches.

## Cached (examples)

- `category/list`, `category/children`
- `shape/list`
- `fonts`
- `public/advertisements`, placements
- `public/contests` (short TTL)
- `public/designs/featured`, `trending`
- `public/app-version`
- `assets/categories`, `assets/meta`
- `referrals/settings`

## Never cached

Auth/user profile mutations, wallet, print, notifications, admin, AI, background-removal, personal `designs/` / `design/`, referral me/apply/withdraw.

## Ops

- TTL is per path prefix in `api_cache_interceptor.dart`.
- Force network: pass `Options(extra: {ApiCacheExtras.forceRefresh: true})`.
- Logout clears keys containing `|u:`.

Backend mirrors this with `HttpGetCache` epoch bumps — see Laravel `docs/HTTP-GET-CACHE.md`.
