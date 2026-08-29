# Design persistence API

All endpoints use the versioned Musamimuk API root and authenticated bearer
token:

`https://srv1813447.hstgr.cloud/api/v1`

## Save

`POST /design/add` as `multipart/form-data`.

Required:

- `file`: PNG, JPG, or PDF preview
- `category_id`
- `name`
- `tags`

Optional:

- `sub_category_id`
- `width`
- `height`
- `visibility`: `public` or `private`
- `design_data`: raw ProImageEditor history JSON string
- `asset_ids[]`: repeated generated-asset UUID field

The Flutter app exports history once, serializes it once with `jsonEncode`, and
sends it unchanged as `design_data`.

The response payload is read from `dbData`; `data` remains a compatibility
fallback.

## Update

`POST /design/update/{id}` as `multipart/form-data`.

All fields are optional and the app sends only values being changed.

- Omitting `file` preserves the preview.
- Omitting `design_data` preserves history.
- Sending explicit null `design_data` clears history.
- Omitting `asset_ids[]` preserves attachments.
- Submitting `asset_ids[]` replaces attachments.

## Redesign

`GET /design/redesign/{id}`

The response includes the preview URL, exact `design_data`, and
`generated_assets`. Flutter passes `design_data` directly to ProImageEditor’s
history import. When history is absent, the preview opens as a flat image and
the user is informed that original layers are unavailable.

Generated asset URLs require the bearer header when loaded.

## Clone public design

`POST /design/clone/{id}` with no body.

After cloning, Flutter reads the new ID from `dbData.id`, loads
`GET /design/redesign/{newId}`, and saves future edits through
`POST /design/update/{newId}`. The source public design is never updated.
