-- ═══════════════════════════════════════════════════════════════════════════
-- EST — Supabase Schema v5 : self-service account recovery (email / phone)
-- Safe to re-run. Run AFTER supabase-schema-v4.sql in the SQL Editor.
--
-- WHAT IT ENABLES (Operations Console → "Forgot password?" / "Forgot username?")
--   1. The user types their registered EMAIL or PHONE.
--   2. A one-time 6-digit code is sent by Supabase Auth (email via the built-in
--      mailer; SMS via the provider configured below).
--   3. They enter the code → identity proven → they set a new password or are
--      shown their username. No admin involvement.
--
-- ONE-TIME SETTINGS (Supabase dashboard → Authentication):
--   • Email templates → "Magic Link": the body MUST contain the code, e.g.
--       <p>Your EST verification code is <b>{{ .Token }}</b> (valid 10 minutes).</p>
--     (the default template only has a link; without {{ .Token }} no code arrives)
--   • Sign In / Providers → Email: "Enable email OTP" on; OTP length 6; expiry 600 s.
--   • Sign In / Providers → Phone: enable and connect an SMS provider.
--       India: Twilio (works for Indian DLT-registered templates) or
--              MessageBird / Vonage; Textlocal is also supported by Supabase.
--     SMS template: "Your EST verification code is {{ .Code }}".
--     Until a provider is connected, the console shows "phone codes not
--     enabled yet" and offers the email route.
--   • Rate limits: Auth → Rate Limits → raise "token verifications" and
--     "emails sent" if your user base is large (free tier: ~4 emails/hour
--     per project — the built-in mailer is for low volume; set up Custom SMTP
--     under Project Settings → Auth for production).
--
-- WHY A "SYNC": codes are sent to the contact stored on the AUTH user
--   (auth.users.email / auth.users.phone). Sign-ups store the person's email
--   there already, but the phone only lives in public.profiles. The function
--   below copies profile phone/email onto the auth user (normalised to E.164)
--   so phone codes work; it also runs automatically when an admin approves or
--   edits an account.
-- ═══════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────
-- A · phone normalisation (Indian numbers default to +91)
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.norm_phone(p text)
returns text language plpgsql immutable as $$
declare d text;
begin
  if p is null then return null; end if;
  d := regexp_replace(p, '[^0-9+]', '', 'g');
  if d = '' then return null; end if;
  if left(d,1) = '+' then
    d := '+' || regexp_replace(substr(d,2), '[^0-9]', '', 'g');
  elsif left(d,2) = '00' then
    d := '+' || substr(d,3);
  elsif length(d) = 10 then
    d := '+91' || d;
  elsif length(d) = 11 and left(d,1) = '0' then
    d := '+91' || substr(d,2);
  elsif length(d) = 12 and left(d,2) = '91' then
    d := '+' || d;
  else
    d := '+' || d;
  end if;
  if length(d) < 11 or length(d) > 16 then return null; end if;
  return d;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- B · lookup_account — does an account exist for this email / phone, and
--     which code channels can reach it? Returns masked hints only.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.lookup_account(p_identifier text)
returns jsonb language plpgsql security definer stable
set search_path = public, auth as $$
declare
  ident text := trim(coalesce(p_identifier,''));
  ph text; em text;
  r record; n int := 0;
  email_hint text := ''; phone_hint text := '';
  email_linked boolean := false; phone_linked boolean := false;
  u_email text; u_phone text;
begin
  if ident = '' then return jsonb_build_object('found', false); end if;

  if position('@' in ident) > 0 then
    em := lower(ident);
    select p.*, u.email as u_email, u.phone as u_phone into r
      from public.profiles p join auth.users u on u.id = p.id
     where lower(p.email) = em or lower(u.email) = em
     order by (p.status = 'approved') desc, p.created_at
     limit 1;
  else
    ph := public.norm_phone(ident);
    if ph is null then return jsonb_build_object('found', false, 'reason', 'bad_phone'); end if;
    select p.*, u.email as u_email, u.phone as u_phone into r
      from public.profiles p join auth.users u on u.id = p.id
     where public.norm_phone(p.phone) = ph or u.phone = ph or u.phone = ltrim(ph,'+')
     order by (p.status = 'approved') desc, p.created_at
     limit 1;
  end if;

  if r is null then return jsonb_build_object('found', false); end if;

  u_email := coalesce(r.u_email,''); u_phone := coalesce(r.u_phone,'');
  -- a usable auth email is a real address, not the synthetic username@est-andaman.in
  email_linked := u_email <> '' and u_email not like '%@est-andaman.in';
  phone_linked := u_phone <> '';
  if email_linked then
    email_hint := left(u_email,1) || '****' || substr(u_email, position('@' in u_email));
  elsif coalesce(r.email,'') <> '' then
    email_hint := left(r.email,1) || '****' || substr(r.email, position('@' in r.email));
  end if;
  if phone_linked then
    phone_hint := '•••• ' || right(u_phone, 4);
  elsif public.norm_phone(r.phone) is not null then
    phone_hint := '•••• ' || right(public.norm_phone(r.phone), 4);
  end if;

  return jsonb_build_object(
    'found', true,
    'status', r.status,
    'email_linked', email_linked,      -- email codes will work
    'phone_linked', phone_linked,      -- SMS codes will work (if provider enabled)
    'email_on_profile', coalesce(r.email,'') <> '',
    'phone_on_profile', public.norm_phone(r.phone) is not null,
    'email_hint', email_hint,
    'phone_hint', phone_hint,
    'auth_email', case when email_linked then u_email else '' end,   -- exact address to send to
    'auth_phone', case when phone_linked then u_phone else '' end
  );
end;
$$;
revoke all on function public.lookup_account(text) from public;
grant execute on function public.lookup_account(text) to anon, authenticated;


-- ───────────────────────────────────────────────────────────────────────────
-- C · sync_auth_contacts — copy profile phone/email onto the auth user so
--     codes can be delivered. Admin-only RPC + automatic on approve/edit.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._sync_one_auth_contact(p_id uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
declare pr public.profiles; ph text; em text;
begin
  select * into pr from public.profiles where id = p_id;
  if pr is null then return; end if;
  -- phone
  ph := public.norm_phone(pr.phone);
  if ph is not null and not exists (select 1 from auth.users where phone = ph and id <> p_id) then
    update auth.users set phone = ph,
           phone_confirmed_at = coalesce(phone_confirmed_at, now()),
           updated_at = now()
     where id = p_id and (phone is distinct from ph);
  end if;
  -- email: replace a synthetic address with the real one from the profile
  em := lower(trim(coalesce(pr.email,'')));
  if em <> '' and position('@' in em) > 1
     and not exists (select 1 from auth.users where lower(email) = em and id <> p_id) then
    update auth.users set email = em,
           email_confirmed_at = coalesce(email_confirmed_at, now()),
           updated_at = now()
     where id = p_id and (lower(email) like '%@est-andaman.in' or email is null);
  end if;
end;
$$;

create or replace function public.sync_auth_contacts()
returns jsonb language plpgsql security definer set search_path = public, auth as $$
declare n int := 0; r record;
begin
  if not public.is_admin() then raise exception 'admins only'; end if;
  for r in select id from public.profiles loop
    perform public._sync_one_auth_contact(r.id); n := n + 1;
  end loop;
  return jsonb_build_object(
    'profiles', n,
    'phone_linked', (select count(*) from auth.users where phone is not null),
    'real_email',   (select count(*) from auth.users where email not like '%@est-andaman.in'));
end;
$$;
revoke all on function public.sync_auth_contacts() from public;
grant execute on function public.sync_auth_contacts() to authenticated;

-- keep the auth user in step when an admin approves or edits contact details
create or replace function public.profiles_sync_contacts_trg()
returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  if (new.status = 'approved' and old.status is distinct from 'approved')
     or new.email is distinct from old.email
     or new.phone is distinct from old.phone then
    perform public._sync_one_auth_contact(new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_sync_contacts on public.profiles;
create trigger profiles_sync_contacts
  after update on public.profiles
  for each row execute procedure public.profiles_sync_contacts_trg();

-- normalise phones already stored in profiles
update public.profiles set phone = public.norm_phone(phone)
 where phone is not null and phone <> '' and public.norm_phone(phone) is not null
   and phone <> public.norm_phone(phone);


-- ───────────────────────────────────────────────────────────────────────────
-- D · recovery_log — every recovery attempt, visible to admins
-- ───────────────────────────────────────────────────────────────────────────
create table if not exists public.recovery_log (
  id bigserial primary key,
  mode text not null check (mode in ('password','username')),
  channel text not null check (channel in ('email','phone')),
  identifier_hint text default '',
  step text not null check (step in ('code_sent','verified','completed','failed')),
  detail text default '',
  at timestamptz default now()
);
alter table public.recovery_log enable row level security;
drop policy if exists "recovery_log: insert"     on public.recovery_log;
drop policy if exists "recovery_log: admin read" on public.recovery_log;
create policy "recovery_log: insert"     on public.recovery_log for insert with check (true);
create policy "recovery_log: admin read" on public.recovery_log for select using (public.is_admin());
