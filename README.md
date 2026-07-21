# EST — Entomological Surveillance Tool

> **Online / Offline · Mobile-First · Cloud-Synced · Progressive Web App**
> Purpose-built for field entomologists, public health workers, and vector control personnel across India.

[![Operations Console](https://img.shields.io/badge/Sign%20In-Operations%20Console-3ecf8e?style=flat-square)](https://sumit3850.github.io/EST-v2.0/signin.html)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg?style=flat-square)](LICENSE)
[![PWA](https://img.shields.io/badge/PWA-Offline--Capable-5a67d8?style=flat-square)](https://sumit3850.github.io/EST-v2.0/)

---

## Access

| Surface | URL | Who |
|---|---|---|
| **Operations Console** (sign in / sign up) | [sumit3850.github.io/EST-v2.0](https://sumit3850.github.io/EST-v2.0/) | Everyone — single sign-on entry |
| **Field App** | `/app.html` (via console) | All approved users |
| **Admin Dashboard** | `/dashboard.html` (via console) | Administrators only |
| **Website** | [estweb](https://estweb-git-main-explorer3850.vercel.app/) | Public |

Sign in once at the console — the Field App and Dashboard open directly with no second login. Install to your home screen from the **Install EST App** button on the console (Android / iOS / Desktop, no app store required).

---

## What Is EST?

**Entomological Surveillance Tool (EST)** is a comprehensive digital platform for systematic mosquito vector surveillance in public health and vector control operations.

Built as a **Progressive Web App (PWA)**, it operates on smartphones, tablets, and desktops — entirely without requiring continuous internet connectivity. Survey data is stored locally on the device and mirrored to a **Supabase cloud database keyed to each user's account**, so a surveyor's data follows them across devices and lands automatically in the central admin dashboard.

---

## How It Works

1. **Sign up** on the Operations Console (name, email, phone, username) → the request appears in the admin dashboard → an **administrator approves** it before first sign-in.
2. **Collect** surveys in the Field App — fully offline if needed, with GPS tracks, per-house tagging, and live WHO indices.
3. **Sync** happens automatically whenever online: every survey is upserted to its module's table in the cloud database. Signing in on a new device restores that user's surveys.
4. **Analyse** in the Admin Dashboard: central database of all synced surveys, Aedes risk assessment, seasonal trend charts, exports, and user management.

Forgot your password or username? The console has self-service recovery — reset links go to your registered email, and every request is also logged for the admin.

---

## Surveillance Modules

### Adult Mosquito Surveillance — 4 Sub-Modules

| Sub-Module | Method | Primary Indices |
|---|---|---|
| **Adult Mosquito Density** | Resting Collection (Indoor/Outdoor Aspirator) | PMHD, TMHD, Room Density, Indoor/Outdoor Density |
| **Human Landing Catch (HLC)** | Per-site human-bait landing collection | PMHD, TMHD |
| **Human Biting Rate (HBR)** | Overnight volunteer bait collection | HBR (mosq/night/vol.), HBR/hr |
| **Adult Biting/Landing Rate (ALR)** | Trap or station-based collection | ALR (adults/bait/hr), ALR/night |

- **25 species** across 5 genera (*Aedes, Anopheles, Culex, Mansonia, Armigeres*)
- **UN-ID log** for unidentified/other specimens with coded entries (UO-001, UO-002…)
- Per-house GPS auto-tagged; live survey path on satellite map

### Larval / Immature Stage Surveillance

| Mosquito | Methodology | Indices |
|---|---|---|
| **Aedes** | 18 container-type matrix; container inspection | House Index (HI), Container Index (CI), Breteau Index (BI), Pupal Index |
| **Anopheles / Culex** | Independent dip-site logging (DS-001…) | Larval Density (LD), Pupal Density (PD), Immature Density (IMD/100 dips) |

### Manual Entry

Paper registers and legacy records entered directly — indices computed automatically, synced to the cloud like any survey.

---

## WHO-Standard Indices Computed

**Adult:** PMHD, TMHD (×10), Indoor/Outdoor Resting Density, Room Density, HBR, HBR/hr, ALR, ALR/night

**Larval Aedes:** HI, CI, BI, Pupal Index · **Larval An./Cx.:** Larval Density, Pupal Density, Immature Density

```
PMHD  = Total Mosquitoes ÷ (Collectors × Total Time hrs)
TMHD  = (Culex ÷ (Collectors × Total Time hrs)) × 10
HBR   = Total Mosquitoes ÷ Nights ÷ Volunteers
ALR   = Total Mosquitoes ÷ (Bait Stations × Hours)
BI    = (Positive Containers ÷ Houses Inspected) × 100
```

> **BI Note:** Displayed as `Nil*` when < 100 houses inspected (per WHO/NVBDCP standard).

---

## Admin Dashboard

- **Central survey database** — every synced survey from every user, filterable and exportable
- **Analytics** — Seasonal Trends (monthly HI/CI/BI line chart + PMHD/TMHD bar chart), **Aedes Breeding Risk Assessment** with module and period selectors, Intervention Tracker — each with one-click printable report generation
- **Survey Maps** — GPS tracks and positive houses on satellite tiles
- **User management** — approve/hold/delete sign-up requests, manage credentials, see password/username reset requests
- **Monthly NVBDCP formats**, bulk PDF / Excel / CSV export, backup & restore

---

## Key Features

- **Offline-first** — works with zero connectivity; syncs when back online
- **Cloud database (Supabase)** — per-account survey storage; cross-device access
- **Single sign-on** — one console login unlocks app and dashboard by role
- **Admin-approved accounts** — new users cannot operate until approved
- **GPS auto-detect** with fallback, outlier filtering, per-house tagging, path recording
- **Satellite map previews** with collision-avoiding labels; **KML export**
- **All-India coverage** — all States/UTs and districts
- **Draft auto-save**; duplicate-safe re-save and edit (records update, never fork)
- **Exports:** PDF (A4 report with maps and signature blocks), Excel/CSV with GPS links, KML, WhatsApp/Email share
- **Installable PWA** on Android, iOS, and desktop

---

## Repository Structure

| File | Purpose |
|---|---|
| `index.html` | Root router → Operations Console |
| `signin.html` | Operations Console — sign in, sign up, password/username recovery, install |
| `app.html` | Field App (single-file PWA) |
| `dashboard.html` | Admin Dashboard |
| `sw.js` | Service Worker — offline-first caching |
| `manifest.json` | PWA manifest |
| `supabase-schema.sql` | Cloud database schema — tables, policies, triggers |
| `config.json` | Legacy credential configuration |
| `data/` | Legacy GitHub-synced survey archive (migrated to Supabase) |

---

## Cloud Database

Survey data lives in a **Supabase** PostgreSQL project: `profiles` (users, roles, approval status), `adult_surveys`, `larval_surveys`, `manual_adult_surveys`, `manual_larval_surveys` (all keyed by username), and `reset_requests`. Run `supabase-schema.sql` in the project's SQL editor to provision or update; the dashboard's **Setup → Migrate GitHub → Supabase** button imports the legacy `data/` archive. GitHub sync remains available as an optional legacy mirror.

---

## Privacy

- Survey data is stored **on-device** and synced to the programme's own cloud database, visible only to the owning account and administrators
- No analytics, no telemetry, no third-party trackers
- See [PRIVACY.md](PRIVACY.md) for the full privacy policy

---

## License

© 2024–2026 Dr. B. Sumit Kumar Rao — All Rights Reserved.

This software is proprietary. Unauthorized reproduction, redistribution, or
commercial use is strictly prohibited. See [LICENSE](LICENSE) for full terms.

---

## Developer

**Dr. B. Sumit Kumar Rao**
State Entomologist
National Vector Borne Disease Control Programme (NVBDCP)
State Health Society, Andaman & Nicobar Islands Administration

| Contact | |
|---|---|
| Email | [explorer3850@gmail.com](mailto:explorer3850@gmail.com) |
| WhatsApp | [+91 95318 06405](https://wa.me/919531806405) |
| Console | [sumit3850.github.io/EST-v2.0](https://sumit3850.github.io/EST-v2.0/) |
