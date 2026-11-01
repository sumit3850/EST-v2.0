// Builds native/www from the web app at the repository root.
//
// The website and the store apps share ONE code base: this script copies the
// pages into www/, makes app.html the entry (index.html), injects the native
// bridge, and leaves the service worker out (the native shell ships the files
// itself; a SW inside the WebView would only fight the app-store update).
import { cpSync, mkdirSync, rmSync, readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const ROOT = join(here, '..', '..');          // repository root
const WWW = join(here, '..', 'www');
const BRIDGE = join(here, '..', 'bridge', 'native-bridge.js');

const PAGES = ['app.html', 'signin.html', 'dashboard.html'];
const STATIC = ['manifest.json', 'dashboard-manifest.json', 'offline-helper.js', 'offline-styles.css', 'config.json', 'PRIVACY.md', 'LICENSE'];
const DIRS = ['data'];                         // legacy reference data used by the pages

rmSync(WWW, { recursive: true, force: true });
mkdirSync(WWW, { recursive: true });

const NATIVE_HEAD = `<script>window.__EST_NATIVE=true;</script>\n<script src="./native-bridge.js" defer></script>\n`;

for (const page of PAGES) {
  const src = join(ROOT, page);
  if (!existsSync(src)) continue;
  let html = readFileSync(src, 'utf8');
  // inject the native marker + bridge right after <head> (first occurrence only)
  html = html.replace(/<head>/i, (m) => m + '\n' + NATIVE_HEAD);
  writeFileSync(join(WWW, page), html);
  if (page === 'app.html') writeFileSync(join(WWW, 'index.html'), html);   // app is the entry point
}
for (const f of STATIC) {
  const src = join(ROOT, f);
  if (existsSync(src)) cpSync(src, join(WWW, f));
}
for (const d of DIRS) {
  const src = join(ROOT, d);
  if (existsSync(src) && statSync(src).isDirectory()) cpSync(src, join(WWW, d), { recursive: true });
}
cpSync(BRIDGE, join(WWW, 'native-bridge.js'));

const count = (dir) => readdirSync(dir, { withFileTypes: true }).reduce((n, e) => n + (e.isDirectory() ? count(join(dir, e.name)) : 1), 0);
console.log(`www built: ${count(WWW)} files → ${WWW}`);
