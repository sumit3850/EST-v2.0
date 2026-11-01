// EST — Razorpay webhook → server-side licence
//
// Razorpay calls this URL after every payment event. We verify the signature
// with the webhook secret, and on a captured payment grant 30 days of Pro to
// the EST username that was passed in the checkout "notes" by the app.
// Nothing the phone says is trusted: the licence row is written here, with
// the service-role key, and the app only ever READS it (is_pro RPC / RLS).
//
// Deploy:  supabase functions deploy razorpay-webhook --no-verify-jwt
// Secrets: supabase secrets set RAZORPAY_WEBHOOK_SECRET=... \
//            SUPABASE_URL=https://<ref>.supabase.co \
//            SUPABASE_SERVICE_ROLE_KEY=...        (Project Settings → API)
// Razorpay dashboard → Settings → Webhooks → Add:
//   URL   https://<ref>.functions.supabase.co/razorpay-webhook
//   Secret the same RAZORPAY_WEBHOOK_SECRET
//   Events payment.captured  (and optionally refund.processed)

import { createClient } from "jsr:@supabase/supabase-js@2";

const WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const LICENSE_DAYS = Number(Deno.env.get("LICENSE_DAYS") ?? "30");
const MIN_AMOUNT_PAISE = Number(Deno.env.get("MIN_AMOUNT_PAISE") ?? "0"); // e.g. 149900 to insist on full price

const enc = new TextEncoder();
const toHex = (buf: ArrayBuffer) =>
  Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");

async function hmacHex(secret: string, body: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return toHex(await crypto.subtle.sign("HMAC", key, enc.encode(body)));
}
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });
  if (!WEBHOOK_SECRET || !SUPABASE_URL || !SERVICE_KEY) return json(500, { error: "function not configured" });

  const raw = await req.text();
  const sig = req.headers.get("x-razorpay-signature") ?? "";
  const expected = await hmacHex(WEBHOOK_SECRET, raw);
  if (!sig || !timingSafeEqual(sig, expected)) return json(401, { error: "bad signature" });

  let evt: any;
  try { evt = JSON.parse(raw); } catch { return json(400, { error: "bad json" }); }

  const sb = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
  const type: string = evt?.event ?? "";
  const payment = evt?.payload?.payment?.entity;

  // ── payment captured → grant / extend Pro ──
  if (type === "payment.captured" && payment) {
    const username: string = String(payment?.notes?.username ?? "").trim();
    const userIdNote: string = String(payment?.notes?.user_id ?? "").trim();
    const paymentId: string = String(payment?.id ?? "");
    const amount = Number(payment?.amount ?? 0);
    if (!username) return json(200, { ok: false, reason: "no username in notes" });
    if (MIN_AMOUNT_PAISE && amount < MIN_AMOUNT_PAISE) return json(200, { ok: false, reason: "amount below licence price" });

    // idempotent: the same payment id never grants twice
    const { data: dup } = await sb.from("licenses").select("id").eq("payment_ref", paymentId).maybeSingle();
    if (dup) return json(200, { ok: true, duplicate: true });

    // resolve the auth user (prefer the id the app sent; fall back to the username)
    let userId: string | null = userIdNote || null;
    if (!userId) {
      const { data: prof } = await sb.from("profiles").select("id").ilike("username", username).maybeSingle();
      userId = prof?.id ?? null;
    }
    // extend from the current expiry when a licence is still running
    const { data: cur } = await sb.from("licenses").select("valid_until")
      .ilike("username", username).eq("plan", "pro")
      .or("valid_until.is.null,valid_until.gt." + new Date().toISOString())
      .order("valid_until", { ascending: false, nullsFirst: true }).limit(1).maybeSingle();
    const base = cur?.valid_until && new Date(cur.valid_until) > new Date() ? new Date(cur.valid_until) : new Date();
    const validUntil = cur && cur.valid_until === null ? null : new Date(base.getTime() + LICENSE_DAYS * 864e5).toISOString();

    const { error } = await sb.from("licenses").insert({
      user_id: userId, username, plan: "pro", source: "razorpay",
      valid_until: validUntil, payment_ref: paymentId,
      note: `₹${(amount / 100).toFixed(0)} · ${payment?.method ?? ""} · ${payment?.email ?? ""} ${payment?.contact ?? ""}`.trim(),
    });
    if (error) return json(500, { error: error.message });
    return json(200, { ok: true, username, valid_until: validUntil });
  }

  // ── refund → end the licence bought with that payment ──
  if (type === "refund.processed") {
    const paymentId: string = String(evt?.payload?.refund?.entity?.payment_id ?? "");
    if (paymentId) await sb.from("licenses").update({ valid_until: new Date().toISOString(), note: "refunded" }).eq("payment_ref", paymentId);
    return json(200, { ok: true, refunded: paymentId });
  }

  return json(200, { ok: true, ignored: type });
});
