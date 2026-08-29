# Background removal

Background removal uses secure application-owned paths only:

1. The authenticated Musamimuk backend endpoint is the preferred path.
2. Local on-device processing is used where the existing feature supports it.
3. Flutter never stores or sends third-party API credentials.

## Existing integration

- `lib/background_removal/background_removal_service.dart`
- `lib/data/repositories/background_removal_repository.dart`
- `lib/data/models/background_removal_api_models.dart`

Backend requests use `ApiClient`, so the Musamimuk bearer token is attached
only to trusted API-origin URLs.

The legacy `HuggingFaceService` and `RemoveBgService` classes remain only for
source compatibility. Their direct third-party network operations are disabled
and they contain no credentials.

## Editor usage

When removing a layer background:

1. Resolve the selected image bytes.
2. Submit them through the existing background-removal controller/repository.
3. Replace or add the returned transparent PNG as an editable image layer.

Do not add API keys, vendor URLs, or client-side vendor SDK calls. Any future
provider integration must be implemented behind the Musamimuk backend.
