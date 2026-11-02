# Play Console submission — ZuviloAI (Android)

What the Play Console forms ask for, with answers that match what the app and API actually do.
Update this file when the app starts collecting something new.

## Before the first upload

- Deploy the web app and API (`deploy/deploy.sh`) so these pages are live. They are referenced
  from the listing and from inside the app:
  - Privacy policy: https://zuviloai.com/privacy
  - Terms of use: https://zuviloai.com/terms
  - Account deletion: https://zuviloai.com/delete-account
- Make sure `help@zuviloai.com` and `privacy@zuviloai.com` receive mail — the app, the
  privacy policy and the deletion page all send people there. (As of 2 Oct 2026
  `zuviloai.com` had no MX records.)
- Enrol in Play App Signing, and register the upload key (SHA-256
  `A4:9D:F4:F7:95:83:30:1C:C6:C0:FA:6F:81:1C:9E:68:66:C1:6F:BF:9E:95:DD:E8:91:FA:EB:F2:C5:4C:A8:5A`).
- After Play App Signing creates the app signing key, add **its** SHA-256 (Play Console → App
  integrity) to `https://zuviloai.com/.well-known/assetlinks.json` (currently 404) so App Links
  verify; until then links open in the browser, which still works.

## Store listing

| Field | Value |
| --- | --- |
| App name | ZuviloAI |
| Package | `com.shubhlms.mobile` |
| App icon | `store/play_store_icon_512.png` |
| Category | Education |
| Contact email | synilogicteam@gmail.com (for now; `help@zuviloai.com` once the domain receives mail) |
| Website | https://zuviloai.com |
| Privacy policy | https://zuviloai.com/privacy |

Still needed from you: a 1024×500 feature graphic and at least two phone screenshots.

## App content

- **Ads:** No ads.
- **App access:** Most of the app needs an account. Give reviewers a learner login (e-mail and
  password) that has at least one enrolled course.
- **Target audience:** 18+ (adult learners). Not designed for children.
- **Content rating:** Education; no violence, sexual content, gambling or user-to-user chat with
  strangers. Learners and instructors can exchange assignment feedback within an academy.
- **Government / financial / health features:** None.
- **News app:** No.

## Account deletion

- Users can create an account in the app: **Yes**.
- In-app path: Profile → Delete account (learners; password-confirmed, immediate).
- Web link: https://zuviloai.com/delete-account
- Data deleted: name, e-mail, lesson notes, bookmarks, saved courses, assignment drafts, live-class
  registrations, notifications, notification preferences, devices and sessions.
- Data retained: course progress, quiz and assignment records and issued certificates, anonymised,
  so issued credentials keep verifying.

## Data safety

Data is encrypted in transit: **Yes** (HTTPS only; cleartext disabled in release builds).
Users can request deletion: **Yes** (above). Data is not sold. No data is shared with third
parties (service providers acting on the academy's behalf don't count as sharing).

| Data type | Collected | Purpose | Optional? |
| --- | --- | --- | --- |
| Personal info → Name | Yes | Account management, App functionality | Required |
| Personal info → Email address | Yes | Account management, App functionality, Developer communications | Required |
| Files and docs | Yes | App functionality (assignment uploads the user picks) | Optional |
| App activity → Other user-generated content | Yes | App functionality (notes, quiz and assignment answers) | Optional |
| App activity → App interactions | Yes | App functionality (course progress, live-class attendance) | Required |
| Device or other IDs | Yes | Fraud prevention, security (sign-in sessions record the device description; IP used for rate limiting) | Required |

Not collected: location, contacts, photos/videos (beyond files the user uploads), audio,
financial info, health, messages, calendar, web history, advertising ID, crash logs, diagnostics.

## Permissions

The release build declares only `INTERNET`, `ACCESS_NETWORK_STATE` and `WAKE_LOCK` (media
playback). There are no runtime permission prompts, so no in-app permission rationale is needed.
File uploads use the system picker, which needs no storage permission.

## Release build

- Target SDK 36, min SDK 24, 64-bit native libraries, 16 KB page-aligned.
- R8 minification and resource shrinking on; native symbol tables are embedded in the bundle.
- Version 1.0.0 (versionCode 1). Raise `version:` in `pubspec.yaml` for every upload.
