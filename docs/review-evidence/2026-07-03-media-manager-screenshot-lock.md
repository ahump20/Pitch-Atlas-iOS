# 2026-07-03 Media Manager Screenshot Lock

Purpose: verify whether the latest build `11` screenshots could be uploaded to
the current App Store Connect Media Manager listing before the `1.1.0` App Store
version exists.

## Live Screenshot Set

- App Store version: `1.0.1`
- Version state: `PENDING_DEVELOPER_RELEASE`
- Localization: `en-US`
- Screenshot set: `ff51940d-6b97-48d1-a970-9643f90a8a25`
- Display type: `APP_IPHONE_67`
- Current files before the write attempt:
  - `01-atlas.png`
  - `02-pitch-detail.png`
  - `03-grips.png`
  - `04-index.png`
  - `05-sources.png`

The current Apple-hosted screenshot files were backed up locally before the write
attempt. The backup was kept outside the repo to avoid committing duplicate store
artifacts.

## Build 11 Screenshots Checked

All five build `11` screenshots in
`docs/review-evidence/2026-07-03-build-11-screens/` were checked at `1320x2868`:

- `01-atlas-home.png`
- `02-pitch-detail-slider.png`
- `03-grips.png`
- `04-index.png`
- `05-sources.png`

## Write Attempt

Request:

```text
POST /v1/appScreenshots
set: ff51940d-6b97-48d1-a970-9643f90a8a25
file: 01-atlas-home.png
```

Apple response:

```json
{
  "errors": [
    {
      "status": "409",
      "code": "ENTITY_ERROR.ATTRIBUTE.INVALID.INVALID_STATE",
      "title": "An attribute value is not acceptable for the current resource state.",
      "source": {
        "pointer": "appScreenshots"
      }
    }
  ]
}
```

Follow-up readback still showed the original five screenshots only. No partial
build `11` screenshot asset was created and no existing screenshot was deleted.

## Result

Media Manager is visible but not writable for this locked `1.0.1` state through
the App Store Connect API. The build `11` screenshots should be uploaded after
the current release slot is made editable or after the new `1.1.0` App Store
version can be created.
