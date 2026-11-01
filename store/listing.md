# EST — store listing kit (Google Play / Apple App Store)

Everything the listing forms ask for, in the order they ask. Copy–paste; edit
the bracketed bits. App id `in.est.surveillance` · Category **Medical** (Play) /
**Medical** (App Store) · Price **Free** (Pro via in-app subscription, Phase 3).

---

## 1. Title, subtitle, descriptions

**Title (30):** EST – Entomological Surveillance

**Short description (80, Play) / Subtitle (30, Apple):**
Play: Mosquito vector surveillance: GPS surveys, WHO indices, risk reports, offline.
Apple: Vector surveillance, offline

**Full description (Play 4000 / Apple 4000):**

EST (Entomological Surveillance Tool) is the field and reporting app for mosquito-vector surveillance teams and stations. It replaces paper registers with GPS-tagged digital surveys, computes WHO / NVBDCP indices live, and turns a month's work into official formats in one tap.

FIELD SURVEYS, OFFLINE FIRST
• Adult surveillance: resting collections, human landing / bait catches, species-wise counts, per-man-hour density.
• Larval surveillance: Aedes (house / container) and Anopheles–Culex (dipping) modules, container-type breakdown, pupal counts.
• Every survey carries the GPS position of its start point and of each house or site; record the survey path with distance and time.
• Works with no network. Data is saved on the device and synced to the programme database when you are back online.

INDICES AND RISK, COMPUTED FOR YOU
• House Index, Container Index, Breteau Index, Pupal and density indices — calculated as you enter data, with WHO risk thresholds.
• Aedes breeding risk assessment by district, region and locality, with comparative charts and breeding-container preferences.

REPORTS AND SHARING
• A4 PDF survey reports, Excel / CSV exports with map links, KML for Google Earth.
• Monthly NVBDCP Aedes larval and adult vector formats, ready to submit.
• Share by email or messaging; satellite map snapshots of survey paths.

ACCOUNTS AND DATA
• Accounts are approved by the programme administrator; each user sees their own surveys, administrators see the programme's.
• Password and username recovery by one-time code to your registered email or mobile.
• Delete your account from inside the app at any time.

FREE AND PRO
• Free: survey entry, GPS, offline storage and sync.
• Pro: density and species analyses, risk assessment, PDF / Excel reports, monthly formats and sharing.

Developed by Dr. B. Sumit Kumar Rao, State Entomologist, NVBDCP – State Health Society, Andaman & Nicobar Islands, and used across the islands' surveillance network.

Privacy policy: https://sumit3850.github.io/EST-v2.0/privacy.html
Terms: https://sumit3850.github.io/EST-v2.0/terms.html
Support: explorer3850@gmail.com

**Keywords (Apple, 100):** mosquito,vector,surveillance,dengue,malaria,entomology,larval,Aedes,NVBDCP,public health

**What's new (first release):** First store release of EST: offline GPS surveys, live WHO indices, Aedes risk assessment, monthly NVBDCP formats, account recovery by email or mobile.

---

## 2. Graphics

| Asset | Size | Source |
|---|---|---|
| App icon | 512×512 PNG (Play), 1024×1024 (Apple) | `native/assets/icon-only.png` (1024) — export 512 for Play |
| Feature graphic (Play) | 1024×500 JPG/PNG | mark + "EST — Entomological Surveillance Tool" on #0d2018 (make from `splash.png`) |
| Phone screenshots | 4–8, 9:16, ≥1080×1920 | see plan below |
| 7" / 10" tablet (optional) | — | dashboard on tablet |

**Screenshot plan (take on a real phone, light data):**
1. Home — module tiles (Adult / Larval / Manual / Saved).
2. Larval survey with GPS captured and container matrix filled.
3. Live indices panel (HI / CI / BI with risk colours).
4. Saved surveys list with sync badges.
5. PDF report preview.
6. Risk-assessment chart (from the dashboard, phone width).
7. Sign-in screen (console) — "Forgot password? code by email or mobile".
Add a 3–5 word caption strip on each (e.g. "Offline GPS surveys").

---

## 3. Google Play — Data safety form (answers)

**Does your app collect or share user data?** Yes.
**Encrypted in transit?** Yes. **Can users request deletion?** Yes (in-app + email).

| Data type | Collected | Shared | Required | Purpose |
|---|---|---|---|---|
| Location → Precise location | Yes | No | Optional (GPS can be denied; surveys save without coordinates) | App functionality |
| Personal info → Name | Yes | No | Required | Account management |
| Personal info → Email address | Yes | No | Required | Account management |
| Personal info → Phone number | Yes | No | Optional | Account management (recovery codes) |
| Personal info → User IDs (username) | Yes | No | Required | Account management |
| Health & fitness → Health info | **No** — entomological counts are environmental surveillance data, not personal health data | — | — | — |
| Photos → Photos | Yes (only if the user attaches one) | No | Optional | App functionality |
| Financial info → Purchase history | Yes (plan + transaction reference, via Play Billing) | No | Optional | App functionality |
| App activity → App interactions | No | — | — | — |
| App info & performance → Crash logs | No | — | — | — |
| Device or other IDs | No | — | — | — |

"Shared" is No because providers (Supabase, payment processors) are processors acting on our instructions, which Play does not count as sharing. Security practices: data encrypted in transit; users can request data deletion; **no** independent security review.

**Permissions declared:** INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CAMERA. No background location (if Play asks: location is used only while the app is in use, to tag survey points).

**Content rating (IARC):** utility / productivity questionnaire → all "No" → Everyone / 3+.
**Target audience:** 18 and over. **Ads:** No. **News app:** No. **COVID-19 contact tracing:** No. **Government app:** You may declare it as a government-affiliated app (A&N Islands health department) — this adds a review step but suits the use.

**Account deletion URL (Play requires a web link):** https://sumit3850.github.io/EST-v2.0/privacy.html#delete-account

---

## 4. Apple — App Privacy ("nutrition label")

Data **linked to the user**: Contact info (name, email, phone), Identifiers (user ID), Location (precise), Purchases, User content (photos, survey entries). Data **not linked**: none. **Tracking:** No.
Purposes: App functionality, Account management. Location usage string (Info.plist): "EST records the GPS position of each survey point and the survey path while you are using the app."
Camera usage string: "EST attaches photos of breeding sites to a survey."
**Sign in with Apple:** not required (no third-party social login is offered).
**Account deletion:** in-app (Home → Delete my account) — required since 2022.
**Age rating:** 4+ (medical/treatment information: none). **Export compliance:** uses only standard HTTPS encryption → exempt (answer "No" to proprietary encryption).

---

## 5. Release checklist

- [ ] Play Console developer account (organisation preferred; personal accounts need a 14-day closed test with ≥12 testers before production).
- [ ] Apple Developer Program (organisation needs a D-U-N-S number — apply early, it takes ~2 weeks).
- [ ] Supabase: schema v4 + v5 applied; email OTP + Magic Link template with `{{ .Token }}`; custom SMTP for volume.
- [ ] `native/README.md` secrets added to GitHub; tag `v2.10.0` → signed `.aab` artifact.
- [ ] Upload .aab to **Internal testing** → add testers (entomology team + 2–3 stations) → fix → **Closed testing** (14 days if personal account) → **Production**.
- [ ] Store listing: texts above, icon 512, feature graphic, 6 screenshots, privacy URL, contact email, Data safety, content rating, target audience, app access (provide a **test account** username/password for reviewers — reviewers cannot wait for admin approval).
- [ ] iOS: build on a Mac (`npx cap add ios`), TestFlight, App Store Connect listing with the same texts; provide the test account in "App Review Information".
- [ ] After approval: note the Play **app signing key** and Apple **bundle id** in your records; versionCode increases automatically per CI run.
