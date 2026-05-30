# EST v2.0 — Entomological Surveillance Tool

> **Online / Offline · Mobile-First · Progressive Web App**
> Purpose-built for field entomologists, public health workers, and vector control personnel across India.

[![Live App](https://img.shields.io/badge/Live%20App-sumit3850.github.io%2FEST--v2.0-006b5c?style=flat-square)](https://sumit3850.github.io/EST-v2.0/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![PWA](https://img.shields.io/badge/PWA-Offline--Capable-5a67d8?style=flat-square)](https://sumit3850.github.io/EST-v2.0/)

---

## Live App

**[https://sumit3850.github.io/EST-v2.0/](https://sumit3850.github.io/EST-v2.0/)**

Install directly to your home screen (Android / iOS / Desktop) — no app store required.

---

## What Is EST?

**Entomological Surveillance Tool (EST)** is a comprehensive digital platform for systematic mosquito vector surveillance in public health and vector control operations.

Built as a **Progressive Web App (PWA)**, it operates seamlessly on smartphones, tablets, and desktops — entirely without requiring continuous internet connectivity. All survey data is stored locally on the device and can be synced to a GitHub-backed cloud database whenever connectivity is available.

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

- Genus-level identification: *Aedes sp., Culex sp., Anopheles sp.* + UN-ID log
- Per-house and per-site GPS auto-tagged; positive houses on satellite map
- **KML export** for Google Earth / Google Maps overlay

---

## WHO-Standard Indices Computed

**Adult Mosquito Density (Resting):** PMHD, TMHD (×10), Indoor/Outdoor Resting Density, Room Density

**Adult Mosquito Density (HLC):** PMHD, TMHD, HBR, HBR/hr

**Human Biting Rate (HBR):** HBR (mosq/night/volunteer), HBR/hr, PMHD, TMHD

**Adult Biting/Landing Rate (ALR):** ALR (adults/bait/hr), ALR/night, ALR Simple

**Larval Aedes:** HI, CI, BI, Pupal Index

**Larval An./Cx.:** Larval Density, Pupal Density, Immature Density

```
PMHD  = Total Mosquitoes ÷ (Collectors × Total Time hrs)
TMHD  = (Culex ÷ (Collectors × Total Time hrs)) × 10
HBR   = Total Mosquitoes ÷ Nights ÷ Volunteers
ALR   = Total Mosquitoes ÷ (Bait Stations × Hours)
BI    = (Positive Containers ÷ Houses Inspected) × 100
```

> **BI Note:** Displayed as `Nil*` when < 100 houses inspected (per WHO/NVBDCP standard).

---

## Key Features

- **Fully offline** — single HTML file; works on any device with a browser
- **GPS auto-detect** with 4-API network fallback
- **Survey path recording** — live GPS track with distance and elapsed time timer
- **GPS outlier filtering** — speed-based rejection (>35 km/h) and accuracy threshold (<40 m) to eliminate jumps
- **Per-house GPS logging** — each house auto-captures GPS coordinates on log
- **Satellite map preview** — survey path + house/site markers on Google Satellite tiles
- **Leader-line map labels** — house and site numbers use collision-avoidance placement with connector lines
- **All-India coverage** — all States/UTs and districts
- **Draft auto-save** — never lose in-progress data (localStorage)
- **Export formats:**
  - **PDF** — printable A4 report with maps, indices, species tables, signature blocks
  - **CSV/Excel** — full detail with GPS coordinates + Google Maps links
  - **KML** — for Google Earth / Google Maps import
  - **WhatsApp / Email** — quick share of summary
- **GitHub cloud sync** — optional; survey data pushed to your own repository
- **Two modules** — Adult & Larval in a single app
- **Progressive Web App** — installable, offline-capable, no app store needed

---

## Repository Structure

| File | Purpose |
|---|---|
| `index.html` | Main EST application (single-file PWA) |
| `dashboard.html` | Admin database dashboard |
| `sw.js` | Service Worker — offline-first caching strategy |
| `manifest.json` | PWA manifest (icons, theme, display mode) |
| `config.json` | User credentials and GitHub database configuration |
| `offline-helper.js` | Offline status helper utilities |
| `offline-styles.css` | Offline indicator styling |
| `data/` | Synced survey data directory (GitHub database mode) |

---

## GitHub Database Setup

The app can optionally sync all survey data to a GitHub repository acting as a cloud database. To configure:

1. Open the app → tap **ⓘ** (About) → **Configure GitHub Database**
2. Enter your GitHub username and repository name
3. Paste a **Personal Access Token** (PAT) with `repo` scope

Once configured, every saved survey is automatically pushed as a JSON file under `data/`.

### Default Dashboard Login

| | |
|---|---|
| **Username** | `ANIENTO` |
| **Password** | `2026` |

> Change credentials via `config.json` in your GitHub repository.

---

## Privacy

EST is designed with privacy-first principles:

- All data stored **locally on-device** (browser `localStorage`)
- No analytics, no telemetry, no third-party trackers
- GitHub sync is **opt-in** and pushes only to your own repository
- GPS data is never transmitted to any external server

See [PRIVACY.md](PRIVACY.md) for the full privacy policy.

---

## License

MIT License — see [LICENSE](LICENSE)

Copyright © 2024–2026 Dr. B. Sumit Kumar Rao

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
| Live App | [sumit3850.github.io/EST-v2.0](https://sumit3850.github.io/EST-v2.0/) |
