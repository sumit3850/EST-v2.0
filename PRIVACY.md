# Privacy Policy

**Entomological Surveillance Tool (EST) v2.0**
Effective Date: 2026-01-01
Last Updated: 2026-05-30

---

## 1. Overview

EST (Entomological Surveillance Tool) is a Progressive Web App (PWA) designed for field-use mosquito vector surveillance. This policy describes what data the application collects, how it is stored, and how it is used.

---

## 2. Data Collected

### 2.1 Survey Data
EST collects the following information entered by the user during field surveys:

- **Survey metadata**: Date, State/UT, District, Location name, Field workers' names
- **Entomological counts**: Species-wise mosquito counts (adult/larval), epidemiological indices
- **GPS coordinates**: Survey start location, per-house/per-site GPS positions, GPS survey track (waypoints recorded during path recording)
- **Environmental observations**: Container inspection data, dipping site data, survey remarks

### 2.2 Authentication Credentials
- Usernames and hashed/XOR-encoded passwords are stored locally to authenticate users offline.
- When a GitHub database is configured, credentials are fetched from the connected repository's `config.json` file.

### 2.3 Device/Browser Information
EST does **not** collect device identifiers, browser fingerprints, IP addresses, or any device-level telemetry.

---

## 3. How Data Is Stored

### 3.1 Local Storage (Primary)
All survey data is stored exclusively in the browser's **`localStorage`** on the user's device. This data:
- Never leaves the device unless you explicitly export or sync it.
- Persists across browser sessions until cleared by the user or the browser.
- Is accessible only within the app on the same device and browser profile.

### 3.2 GitHub Cloud Database (Optional — User-Configured)
If you configure a GitHub repository as a cloud database:
- Survey data (JSON) is pushed to your **own** GitHub repository via the GitHub REST API.
- A Personal Access Token (PAT) you provide is stored locally (XOR-encoded) in `config.json`; it is **never transmitted to any server other than GitHub's API**.
- The data in your GitHub repository is subject to [GitHub's Privacy Policy](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).

### 3.3 Service Worker Cache
EST uses a Service Worker to enable offline functionality. Static assets (HTML, CSS, JS, JSON) are cached in the browser's **Cache Storage**. No survey data is stored in the service worker cache.

---

## 4. GPS and Location Data

- GPS coordinates are captured using the browser's **Geolocation API** when you initiate a survey or tap "Get GPS".
- Survey path waypoints are recorded locally during active track recording sessions only.
- Location data is stored solely in `localStorage` on your device and, if configured, in your GitHub repository.
- EST does **not** transmit GPS data to any third-party service.

---

## 5. Data Sharing

EST does **not**:
- Share any data with third parties, advertisers, or analytics services.
- Use cookies for tracking.
- Include any analytics, telemetry, or crash-reporting SDKs.
- Transmit data to any server other than GitHub (only when you have explicitly configured a GitHub database and triggered a sync).

Map tiles used in survey map previews are fetched from **Google Maps** (`mt0–mt3.google.com`). This request includes your map coordinates. Google's use of this data is governed by the [Google Privacy Policy](https://policies.google.com/privacy). No user account data is sent with tile requests.

---

## 6. Data Retention and Deletion

- Survey data persists in `localStorage` until you delete it from within the app (Settings → Delete Survey) or clear your browser's site data.
- To completely remove all EST data from your device: open your browser settings → Site Data → find EST's domain → clear data.
- If you have synced data to GitHub, deleting it from the app does not automatically delete it from your repository; you must delete it from GitHub manually.

---

## 7. Children's Privacy

EST is designed for professional public health and field research use. It is not directed at children under 13 and does not knowingly collect information from minors.

---

## 8. Security

- Authentication tokens/passwords are stored using XOR-encoding (not plain text).
- GitHub Personal Access Tokens are stored locally only; never logged or transmitted to any service other than `api.github.com`.
- All GitHub API requests use HTTPS.

---

## 9. Changes to This Policy

Updates to this policy will be reflected in the app's About page and in the repository's `PRIVACY.md`. Continued use of the app after changes constitutes acceptance of the updated policy.

---

## 10. Contact

For privacy-related questions or data deletion requests:

**Dr. B. Sumit Kumar Rao**
State Entomologist, NVBDCP
State Health Society, Andaman & Nicobar Islands

- Email: [explorer3850@gmail.com](mailto:explorer3850@gmail.com)
- WhatsApp: +91 95318 06405
