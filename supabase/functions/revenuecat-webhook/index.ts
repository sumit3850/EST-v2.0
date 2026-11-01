// EST — RevenueCat webhook → server-side licence (Google Play / App Store)
//
// The store apps sell the Pro subscription through Play Billing / Apple IAP via
// RevenueCat (one SDK for both stores, receipt validation done by RevenueCat).
// RevenueCat calls this URL on every subscription event; we authenticate the
// call with a shared secret and mirror the entitlement into `licenses`, keyed
// by the Supabase user id that the app registers as the RevenueCat app user id.
// The app never writes licences — it only reads is_pro().
//
// Deploy:  supabase functions deploy revenuecat-webhook --no-verify-jwt
// Secrets: supabase secrets set REVENUECAT_WEBHOOK_AUTH='Bearer <long-random>' \
//            SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=...
// RevenueCat dashboard → Project → Integrations → Webhooks:
//   URL   https://<ref>.functions.supabase.co/revenuecat-webhook
//   Authorization header value: the same REVENUECAT_WEBHOOK_AUTH
//   Entitlement identifier in RevenueCat: "pro"

import { createClient } from "jsr:@supabase/supabase-js@2";

const AUTH = Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ENTITLEMENT = Deno.env.get("RC_ENTITLEMENT") ?? "pro";

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

const GRANT = new Set(["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "NON_RENEWING_PURCHASE", "PRODUCT_CHANGE", "TRANSFER", "SUBSCRIPTION_EXTENDED", "TEMPORARY_ENTITLEMENT_GRANT"]);
const END = new Set(["EXPIRATION", "REFUND", "SUBSCRIPTION_PAUSED"]);
// CANCELLATION = auto-renew switched off: access continues until expiration_at_ms → no change now.
// BILLING_ISSUE: grace period handled by the store; expiration event follows if unpaid.

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });
  if (!AUTH || !SUPABASE_URL || !SERVICE_KEY) return json(500, { error: "function not configured" });
  if ((req.headers.get("authorization") ?? "") !== AUTH) return json(401, { error: "unauthorized" });

  let body: any;
  try { body = await req.json(); } catch { return json(400, { error: "bad json" }); }
  const ev = body?.event ?? {};
  const type: string = ev.type ?? "";
  const store: string = String(ev.store ?? "").toUpperCase();            // PLAY_STORE | APP_STORE | …
  const source = store.includes("PLAY") ? "play" : store.includes("APP") ? "apple" : "manual";
  const appUserId: string = String(ev.app_user_id ?? "");                // Supabase auth uid set by the app
  const aliases: string[] = Array.isArray(ev.aliases) ? ev.aliases : [];
  const txn: string = String(ev.transaction_id ?? ev.original_transaction_id ?? ev.id ?? "");
  const ents: string[] = Array.isArray(ev.entitlement_ids) ? ev.entitlement_ids : (ev.entitlement_id ? [ev.entitlement_id] : []);
  if (ents.length && !ents.includes(ENTITLEMENT)) return json(200, { ok: true, ignored: "other entitlement" });

  const sb = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

  // resolve the user: app_user_id (or an alias) must be a Supabase auth uid
  const candidates = [appUserId, ...aliases].filter((s) => /^[0-9a-f-]{36}$/i.test(s));
  let profile: { id: string; username: string } | null = null;
  for (const id of candidates) {
    const { data } = await sb.from("profiles").select("id,username").eq("id", id).maybeSingle();
    if (data) { profile = data; break; }
  }
  if (!profile) return json(200, { ok: false, reason: "no profile for app_user_id", appUserId });

  if (GRANT.has(type)) {
    const validUntil = ev.expiration_at_ms ? new Date(Number(ev.expiration_at_ms)).toISOString() : null;
    // one row per (user, store transaction); renewals update the expiry
    const key = `${source}:${txn || ev.original_transaction_id || "sub"}`;
    const { data: existing } = await sb.from("licenses").select("id").eq("payment_ref", key).maybeSingle();
    const row = { user_id: profile.id, username: profile.username, plan: "pro", source, valid_until: validUntil, payment_ref: key,
      note: `${type} · ${ev.product_id ?? ""} · ${ev.period_type ?? ""} · ${ev.environment ?? ""}`.trim() };
    const { error } = existing
      ? await sb.from("licenses").update(row).eq("id", existing.id)
      : await sb.from("licenses").insert(row);
    if (error) return json(500, { error: error.message });
    return json(200, { ok: true, type, username: profile.username, valid_until: validUntil });
  }

  if (END.has(type)) {
    const { error } = await sb.from("licenses").update({ valid_until: new Date().toISOString(), note: type })
      .eq("user_id", profile.id).eq("source", source).or("valid_until.is.null,valid_until.gt." + new Date().toISOString());
    if (error) return json(500, { error: error.message });
    return json(200, { ok: true, type, ended: true });
  }

  return json(200, { ok: true, ignored: type });
});
