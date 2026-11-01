-- ═══════════════════════════════════════════════════════════════════════════
-- EST — Supabase Schema v4 : accounts, data isolation, licences
-- Safe to re-run. Run AFTER supabase-schema.sql (v3) in the SQL Editor.
-- Project: fivqdckmtymtuxlhjjoj
--
-- WHY: the store apps (Google Play / App Store) and paid Pro features need
--   • every user to be a real Supabase Auth account (no config.json list),
--   • survey rows owned by auth.uid() and protected by RLS,
--   • the Free/Pro licence decided on the server, never in localStorage,
--   • an in-app "Delete my account" (required by both stores).
--
-- HOW TO ROLL OUT (two steps, so nothing breaks while users migrate):
--   STEP 1 (now)   — run PART A..D. Adds licences, helpers, user_id backfill,
--                    account deletion. Existing open policies keep working.
--   STEP 2 (later) — once every active user signs in through Supabase Auth
--                    (dashboard ⚙ Setup shows "legacy sign-ins: 0" for 7 days),
--                    run PART E to lock the survey tables to their owners.
--
-- AUTH SETTINGS (Supabase dashboard → Authentication):
--   • Email provider ON.
--   • "Confirm email": OFF (EST approves accounts via the dashboard).
--   • URL configuration → Redirect URLs: add
--       https://sumit3850.github.io/EST-v2.0/signin.html
--       https://sumit3850.github.io/EST-v2.0/app.html
--       in.gov.and.est://auth   (the Capacitor app's deep link, Phase 2)
--   • Email templates → "Reset password": keep default; the apps handle the
--     PASSWORD_RECOVERY event and ask for the new password.
-- ═══════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────
-- PART A · helpers
-- ───────────────────────────────────────────────────────────────────────────

-- EST username of the signed-in user (profiles is the registry)
create or replace function public.my_username()
returns text language sql security definer stable
set search_path = public as $$
  select username from public.profiles where id = auth.uid();
$$;

-- Approved field user or admin?
create or replace function public.is_approved()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists(select 1 from public.profiles
                where id = auth.uid() and status = 'approved');
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- PART B · licences (Free / Pro) — the single source of truth for Pro access
-- ───────────────────────────────────────────────────────────────────────────
create table if not exists public.licenses (
  id            bigserial primary key,
  user_id       uuid references auth.users(id) on delete cascade,
  username      text not null default '',          -- EST username (legacy key)
  plan          text not null default 'pro' check (plan in ('free','pro')),
  source        text not null default 'manual'
                check (source in ('manual','razorpay','play','apple','grandfathered')),
  valid_from    timestamptz not null default now(),
  valid_until   timestamptz,                         -- null = never expires
  payment_ref   text default '',                     -- Razorpay payment id / store transaction id
  granted_by    text default '',                     -- admin username for manual grants
  note          text default '',
  created_at    timestamptz default now()
);
create index if not exists licenses_user_idx     on public.licenses(user_id);
create index if not exists licenses_username_idx on public.licenses(lower(username));
alter table public.licenses enable row level security;

-- Users read their own licences; admins read everything.
-- NOBODY writes through the API key: licences are written only by
--   • the Razorpay / RevenueCat webhooks (Edge Functions, service role), or
--   • admins via grant_license() below.
drop policy if exists "licenses: own read"   on public.licenses;
drop policy if exists "licenses: admin read" on public.licenses;
create policy "licenses: own read"   on public.licenses for select
  using (user_id = auth.uid() or lower(username) = lower(public.my_username()));
create policy "licenses: admin read" on public.licenses for select
  using (public.is_admin());

-- Is the signed-in user Pro right now?  Admins always are.
create or replace function public.is_pro()
returns boolean language sql security definer stable
set search_path = public as $$
  select public.is_admin() or exists(
    select 1 from public.licenses l
    where (l.user_id = auth.uid() or lower(l.username) = lower(public.my_username()))
      and l.plan = 'pro'
      and l.valid_from <= now()
      and (l.valid_until is null or l.valid_until > now())
  );
$$;

-- Admin grants/extends a licence (invoice / bank-transfer / grandfathered users)
create or replace function public.grant_license(
  p_username text, p_days int default 365, p_source text default 'manual', p_note text default '')
returns public.licenses language plpgsql security definer
set search_path = public as $$
declare r public.licenses; uid uuid;
begin
  if not public.is_admin() then raise exception 'admins only'; end if;
  select id into uid from public.profiles where lower(username) = lower(p_username);
  insert into public.licenses (user_id, username, plan, source, valid_until, granted_by, note)
  values (uid, p_username, 'pro', p_source,
          case when p_days is null then null else now() + make_interval(days => p_days) end,
          coalesce(public.my_username(),''), p_note)
  returning * into r;
  return r;
end;
$$;

-- Admin revokes (ends) all active licences of a user
create or replace function public.revoke_license(p_username text)
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not public.is_admin() then raise exception 'admins only'; end if;
  update public.licenses set valid_until = now()
   where lower(username) = lower(p_username)
     and (valid_until is null or valid_until > now());
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Grandfather the founding accounts (matches GRANDFATHERED_USERS in the app)
insert into public.licenses (user_id, username, plan, source, valid_until, note)
select p.id, p.username, 'pro', 'grandfathered', null, 'founding account'
from public.profiles p
where lower(p.username) in ('aniento','sumit-1','shiva-1','shivan-1')
  and not exists (select 1 from public.licenses l where lower(l.username) = lower(p.username));


-- ───────────────────────────────────────────────────────────────────────────
-- PART C · survey ownership — fill user_id from username so RLS can use it
-- ───────────────────────────────────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['adult_surveys','larval_surveys','manual_adult_surveys','manual_larval_surveys'] loop
    execute format($f$
      update public.%I s set user_id = p.id
      from public.profiles p
      where s.user_id is null and lower(s.username) = lower(p.username)$f$, t);
    -- keep user_id filled automatically for new rows written with a session
    execute format('create index if not exists %I on public.%I(user_id)', t||'_user_id_idx', t);
  end loop;
end $$;

-- Trigger: stamp user_id / username from the session on insert when missing
create or replace function public.stamp_survey_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.user_id is null and auth.uid() is not null then new.user_id := auth.uid(); end if;
  if (new.username is null or new.username = '') and auth.uid() is not null then
    new.username := coalesce(public.my_username(), '');
  end if;
  return new;
end;
$$;
do $$
declare t text;
begin
  foreach t in array array['adult_surveys','larval_surveys','manual_adult_surveys','manual_larval_surveys'] loop
    execute format('drop trigger if exists stamp_owner on public.%I', t);
    execute format('create trigger stamp_owner before insert on public.%I
                    for each row execute procedure public.stamp_survey_owner()', t);
  end loop;
end $$;


-- ───────────────────────────────────────────────────────────────────────────
-- PART D · account deletion (Google Play & App Store requirement)
-- Deletes the auth user; profiles/licences cascade; surveys are KEPT for the
-- programme's records but anonymised (owner cleared, username kept as text
-- so historical station reports still read correctly).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not signed in'; end if;
  update public.adult_surveys         set user_id = null where user_id = uid;
  update public.larval_surveys        set user_id = null where user_id = uid;
  update public.manual_adult_surveys  set user_id = null where user_id = uid;
  update public.manual_larval_surveys set user_id = null where user_id = uid;
  delete from auth.users where id = uid;   -- cascades to profiles, licenses
end;
$$;
revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

-- Sign-in audit: lets the dashboard show how many legacy (config.json)
-- sign-ins still happen, so you know when PART E is safe to run.
create table if not exists public.signin_log (
  id bigserial primary key,
  username text default '',
  method   text not null check (method in ('legacy','supabase')),
  app      text default '',          -- 'app' | 'dashboard' | 'console'
  at       timestamptz default now()
);
alter table public.signin_log enable row level security;
drop policy if exists "signin_log: insert"     on public.signin_log;
drop policy if exists "signin_log: admin read" on public.signin_log;
create policy "signin_log: insert"     on public.signin_log for insert with check (true);
create policy "signin_log: admin read" on public.signin_log for select using (public.is_admin());


-- ═══════════════════════════════════════════════════════════════════════════
-- PART E · LOCK-DOWN  —  run ONLY in STEP 2 (all users on Supabase Auth)
-- Replaces the "open" policies: a signed-in, approved user sees and edits
-- only their own rows; admins see everything; the anonymous key can do
-- nothing. The field app must by then send the user's session token.
-- ═══════════════════════════════════════════════════════════════════════════
-- do $$
-- declare t text;
-- begin
--   foreach t in array array['adult_surveys','larval_surveys','manual_adult_surveys','manual_larval_surveys'] loop
--     execute format('drop policy if exists "%s: open read"   on public.%I', t, t);
--     execute format('drop policy if exists "%s: open insert" on public.%I', t, t);
--     execute format('drop policy if exists "%s: open update" on public.%I', t, t);
--     execute format('drop policy if exists "%s: open delete" on public.%I', t, t);
--     execute format('drop policy if exists "%s: own read"    on public.%I', t, t);
--     execute format('drop policy if exists "%s: own write"   on public.%I', t, t);
--     execute format('drop policy if exists "%s: own update"  on public.%I', t, t);
--     execute format('drop policy if exists "%s: own delete"  on public.%I', t, t);
--     execute format('create policy "%s: own read"   on public.%I for select to authenticated
--                     using (public.is_admin() or user_id = auth.uid() or lower(username) = lower(public.my_username()))', t, t);
--     execute format('create policy "%s: own write"  on public.%I for insert to authenticated
--                     with check (public.is_approved())', t, t);
--     execute format('create policy "%s: own update" on public.%I for update to authenticated
--                     using (public.is_admin() or user_id = auth.uid() or lower(username) = lower(public.my_username()))', t, t);
--     execute format('create policy "%s: own delete" on public.%I for delete to authenticated
--                     using (public.is_admin() or user_id = auth.uid() or lower(username) = lower(public.my_username()))', t, t);
--   end loop;
-- end $$;
-- -- profiles: remove the anonymous policies the dashboard no longer needs
-- drop policy if exists "profiles: anon read"   on public.profiles;
-- drop policy if exists "profiles: anon update" on public.profiles;
-- drop policy if exists "profiles: anon delete" on public.profiles;
-- -- user_permissions / reset_requests: admin-managed, user-readable
-- drop policy if exists "user_permissions: open insert" on public.user_permissions;
-- drop policy if exists "user_permissions: open update" on public.user_permissions;
-- drop policy if exists "user_permissions: open delete" on public.user_permissions;
-- create policy "user_permissions: admin write" on public.user_permissions for all to authenticated
--   using (public.is_admin()) with check (public.is_admin());
-- drop policy if exists "reset_requests: open read"   on public.reset_requests;
-- drop policy if exists "reset_requests: open update" on public.reset_requests;
-- drop policy if exists "reset_requests: open delete" on public.reset_requests;
-- create policy "reset_requests: admin manage" on public.reset_requests for all to authenticated
--   using (public.is_admin()) with check (public.is_admin());
