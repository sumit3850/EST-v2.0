# EST v2.0 — Entomological Surveillance Tool
### Adult & Larval Mosquito Surveillance · A&N Islands

---

## 🌐 Live App
👉 **[Open EST v2.0](https://sumit3850.github.io/EST-v2.0/)**

Bookmark this link or tap **Add to Home Screen** in Chrome to install as an app icon.

---

## 📱 First Time Setup (Field Staff)
1. Open the link above **once while connected to the internet**
2. App caches automatically — works fully offline after that
3. When update is available, a green banner will appear — tap **Reload**

---

## 🔐 Default Login
| Field | Value |
|-------|-------|
| Username | ANIENTO |
| Password | 2026 |

To change credentials: edit `config.json` in this repo and commit.

---

## 🗄️ GitHub Database Setup (Admin)
1. Open EST app → About → **Configure GitHub Database**
2. Enter:
   - **Username:** `sumit3850`
   - **Repo:** `EST-v2.0`
   - **Token:** *(your Personal Access Token with `repo` scope)*
3. Tap **Save & Connect**

Surveys will then auto-sync to this repo under `data/YYYY-MM/` after each save.

---

## 📊 Database Dashboard
Open `dashboard.html` in any browser → enter same GitHub credentials → view all surveys, export CSV, manage users.

---

## 🔄 Updating the App
1. Replace `index.html` in this repo with the new version
2. Bump the version: `<meta name="est-version" content="2.0.X">`
3. Commit → GitHub Pages publishes in ~1 minute
4. All users see **"Update Available"** banner next time they open app online

---

## 📁 Repository Structure
```
EST-v2.0/
├── index.html          ← EST app (main file users access)
├── dashboard.html      ← Admin database dashboard
├── config.json         ← User credentials (edit to manage access)
├── README.md           ← This file
└── data/               ← Survey data (auto-created by app)
    ├── 2025-05/
    │   ├── adult-2025-05-25-....json
    │   └── larval-2025-05-25-....json
    └── ...
```

---

## 👨‍💼 Developer
**Dr. B. Sumit Kumar Rao**
State Entomologist · Directorate of Health Services · A&N Administration
📧 explorer3850@gmail.com | 📞 +91 95318 06405

---
*EST v2.0 · Offline HTML5 PWA · No server required · Data stored in GitHub*
