# Deploying assetlinks.json (B13)

Generated 2026-09-30T13:31:31Z from `/Users/mac/.android/debug.keystore` (alias `androiddebugkey`).
Fingerprint: `42:94:30:E1:23:05:3D:29:E3:5E:36:D4:AC:5E:2A:3B:70:51:37:CE:1F:8B:15:B6:64:20:39:BD:77:F9:EE:C6`

Android will only open the academy's links in the app once this file is served, **unencoded**, at

    https://zuviloai.com/.well-known/assetlinks.json

with `Content-Type: application/json`, over https, with no redirect. Until then the links open the
browser and the web app handles them, which is the intended fallback.

## The step a human takes

Production builds this file from the environment (`apps/api/src/lib/appLinks.ts`), never from this
debug-keyed copy, which is for local verification only. CloudPanel's vhost answers `/.well-known/` from
the site root and never forwards it to the API, so `deploy.sh` writes the file there
(`npm run app-links:publish`, into `<site>/.well-known/assetlinks.json`) on every deploy.

The upload key (`CN=ZuviloAI, O=Synilogic Tech`), which signs the release bundle and the sideloaded
release APKs, has the SHA-256
`A4:9D:F4:F7:95:83:30:1C:C6:C0:FA:6F:81:1C:9E:68:66:C1:6F:BF:9E:95:DD:E8:91:FA:EB:F2:C5:4C:A8:5A`.

1. In Play Console › Test and release › App integrity, copy the **App signing key certificate**
   SHA-256 (and the upload key's, if sideloaded release builds should verify too).
2. On the server, set in `apps/api/.env` and redeploy:
   `ANDROID_APP_LINK_SHA256=<Play app signing SHA-256>,<upload key SHA-256 above>`.
3. Confirm it is served: `curl -sI https://zuviloai.com/.well-known/assetlinks.json`
   returns 200 and `application/json`.
4. Reinstall the app, then check Android agrees:
   `adb shell pm get-app-links com.shubhlms.mobile.dev` should report `verified` for the host.

## Checking the routes without the file (dev)

Verification can be overridden locally, which is how the acceptance criteria were checked:

    adb shell pm set-app-links --package com.shubhlms.mobile.dev 0 all
    adb shell pm verify-app-links --re-verify com.shubhlms.mobile.dev
    adb shell am start -a android.intent.action.VIEW \
      -d "https://zuviloai.com/verify/SA-JY-2026-00142"

## When the release key exists (C6/C16)

Re-run with that keystore and replace the file — a release build signed with a different certificate
will not verify against a debug fingerprint:

    KEYSTORE=/path/to/release.jks ALIAS=upload STOREPASS=… tool/assetlinks.sh
