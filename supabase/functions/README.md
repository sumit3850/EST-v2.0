# EST — Supabase Edge Functions

Server-side pieces that must never run on a phone: payment verification and
licence writes. Everything here needs the **Supabase CLI** once on your laptop
(`npm i -g supabase`, then `supabase login`).

Project ref: `fivqdckmtymtuxlhjjoj`

## razorpay-webhook — Pro licence from a web (Razorpay) payment

What it does: Razorpay calls the function after a payment; the function checks
the signature and inserts a `licenses` row (30 days of Pro, extended from the
current expiry if one is running). The app then sees Pro through `is_pro()`.
Refunds end the licence. The same payment id can never grant twice.

### One-time setup

```bash
supabase link --project-ref fivqdckmtymtuxlhjjoj

# secrets (Project Settings → API for the service-role key; choose any long
# random string as the webhook secret and use the SAME one in Razorpay)
supabase secrets set \
  RAZORPAY_WEBHOOK_SECRET='choose-a-long-random-secret' \
  SUPABASE_URL='https://fivqdckmtymtuxlhjjoj.supabase.co' \
  SUPABASE_SERVICE_ROLE_KEY='eyJ...service role...' \
  LICENSE_DAYS=30 \
  MIN_AMOUNT_PAISE=149900

# deploy (no JWT: Razorpay is authenticated by the signature, not a user)
supabase functions deploy razorpay-webhook --no-verify-jwt
```

Razorpay Dashboard → **Settings → Webhooks → + Add New Webhook**
- Webhook URL: `https://fivqdckmtymtuxlhjjoj.functions.supabase.co/razorpay-webhook`
- Secret: the `RAZORPAY_WEBHOOK_SECRET` above
- Active events: `payment.captured`, `refund.processed`

### Test

Razorpay → Webhooks → your webhook → **Send test**, or make a ₹1 payment with
`MIN_AMOUNT_PAISE=0` temporarily. Then in the SQL editor:

```sql
select username, plan, source, valid_until, payment_ref, note
from public.licenses order by created_at desc limit 10;
```

Logs: Supabase → Edge Functions → razorpay-webhook → Logs.

### How the app side works now

- The field app passes `notes.username` (and `notes.user_id` when signed in
  with a Supabase account) to Razorpay Checkout; the webhook uses them to
  attach the licence.
- After a successful payment the app shows Pro immediately (local marker,
  "pending server confirmation") and re-checks `is_pro()` a few times over the
  next minute; once the webhook has written the row, the server answer wins.
- Admins can grant/extend/revoke manually from the dashboard (Users panel) for
  invoice / bank-transfer buyers — `grant_license()` / `revoke_license()` from
  schema v4.

## revenuecat-webhook — Pro licence from Google Play / App Store (Phase 3)

Store apps must sell digital features through Play Billing / Apple IAP.
RevenueCat fronts both stores (receipt validation, renewals, refunds) and calls
this function on every subscription event; it mirrors the "pro" entitlement into
the same `licenses` table with `source` `play` / `apple`. The app only reads
`is_pro()`, so nothing else changes.

### One-time setup (after the store developer accounts exist)

1. **Stores**: create the subscription product in Play Console
   (`est_pro_monthly`, ₹1,499 / month) and in App Store Connect (same id);
   fill the store's tax/payments profile.
2. **RevenueCat** (free up to US$2.5k MTR): new project → add the Play app
   (upload the Play service-account JSON) and the iOS app (App Store Connect
   API key) → Products: import `est_pro_monthly` from both → Entitlement
   **`pro`** attached to both products → Offering `default`.
3. **Deploy this function** and secrets:
   ```bash
   supabase secrets set REVENUECAT_WEBHOOK_AUTH='Bearer <long-random-string>'
   supabase functions deploy revenuecat-webhook --no-verify-jwt
   ```
   RevenueCat → Integrations → Webhooks → URL
   `https://fivqdckmtymtuxlhjjoj.functions.supabase.co/revenuecat-webhook`,
   Authorization header = the same value.
4. **App wiring** (done in the Capacitor shell once the RevenueCat public SDK
   keys exist): `@revenuecat/purchases-capacitor` is configured with the Play /
   Apple public key and **`appUserID` = the Supabase auth user id**, so events
   arrive with `app_user_id` = `profiles.id`. The "Subscribe" button in the
   payment dialog calls `Purchases.purchasePackage(default offering)`; on
   success the app re-checks `is_pro()` (webhook latency is seconds).
5. **Test** with Play licence testers / Apple sandbox accounts; check
   `select * from licenses order by created_at desc` and the function logs.

Event handling: INITIAL_PURCHASE / RENEWAL / UNCANCELLATION / PRODUCT_CHANGE /
TRANSFER → upsert Pro until `expiration_at_ms`; EXPIRATION / REFUND /
SUBSCRIPTION_PAUSED → end the licence now; CANCELLATION (auto-renew off) leaves
access until expiry; BILLING_ISSUE is left to the store's grace period.
