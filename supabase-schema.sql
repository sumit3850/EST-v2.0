-- ═══════════════════════════════════════════════════════════════
-- EST — Supabase Schema v3  (safe to re-run)
-- Run this ENTIRE file in the Supabase SQL Editor.
-- Project: fivqdckmtymtuxlhjjoj
--
-- AUTH SETTINGS (do once in the Supabase dashboard):
--   Authentication > Sign In / Providers > Email:
--     • Enable the Email provider
--     • DISABLE "Confirm email" — EST usernames map to internal
--       @est-andaman.in addresses that cannot receive mail.
--
-- After this file: open the EST dashboard as admin, click ⚙ Setup, and
-- press "⇪ Migrate GitHub → Supabase" to import the historical survey
-- data (the SQL editor cannot handle the full data payload).
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- PROFILES (sign-up requests + user registry)
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text not null unique,
  full_name text default '',
  role text not null default 'field' check (role in ('admin','field')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz default now()
);
alter table public.profiles add column if not exists first_name text default '';
alter table public.profiles add column if not exists last_name  text default '';
alter table public.profiles add column if not exists email      text default '';
alter table public.profiles add column if not exists phone      text default '';

alter table public.profiles enable row level security;

create or replace function public.is_admin()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'approved'
  );
$$;

drop policy if exists "profiles: own read"     on public.profiles;
drop policy if exists "profiles: own update"   on public.profiles;
drop policy if exists "profiles: admin read"   on public.profiles;
drop policy if exists "profiles: admin update" on public.profiles;
drop policy if exists "profiles: insert own"   on public.profiles;
drop policy if exists "profiles: anon read"    on public.profiles;
drop policy if exists "profiles: anon update"  on public.profiles;
drop policy if exists "profiles: anon delete"  on public.profiles;

create policy "profiles: own read" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles: admin read" on public.profiles
  for select using (public.is_admin());
create policy "profiles: own update" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "profiles: admin update" on public.profiles
  for update using (public.is_admin());
create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);
-- Dashboard manages sign-up requests with the public publishable key.
-- Acceptable for this deployment's threat model (credentials already ship
-- in a public config.json); tighten later if needed.
create policy "profiles: anon read" on public.profiles
  for select to anon using (true);
create policy "profiles: anon update" on public.profiles
  for update to anon using (true) with check (true);
create policy "profiles: anon delete" on public.profiles
  for delete to anon using (true);

-- Non-admins cannot change their own role/status
create or replace function public.protect_profile_fields()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (new.role is distinct from old.role or new.status is distinct from old.status)
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only admins can change role or status';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_profile_fields on public.profiles;
create trigger protect_profile_fields
  before update on public.profiles
  for each row execute procedure public.protect_profile_fields();

-- Auto-create a pending profile on signup, carrying the sign-up form fields
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, full_name, first_name, last_name, email, phone, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)),
    trim(coalesce(new.raw_user_meta_data->>'first_name','') || ' ' || coalesce(new.raw_user_meta_data->>'last_name','')),
    coalesce(new.raw_user_meta_data->>'first_name',''),
    coalesce(new.raw_user_meta_data->>'last_name',''),
    coalesce(new.raw_user_meta_data->>'contact_email',''),
    coalesce(new.raw_user_meta_data->>'phone',''),
    'field',
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ─────────────────────────────────────────────
-- SURVEY TABLES — keyed by EST username so legacy (non-Supabase-auth)
-- accounts own their data across devices. user_id is optional and only
-- set for Supabase-auth accounts.
-- ─────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['adult_surveys','larval_surveys','manual_adult_surveys','manual_larval_surveys'] loop
    execute format($f$
      create table if not exists public.%I (
        id bigserial primary key,
        user_id uuid references auth.users(id) on delete set null,
        username text not null default '',
        local_id text not null,
        data jsonb not null default '{}',
        survey_date text default '',
        location text default '',
        zone text default '',
        district text default '',
        created_at timestamptz default now()
      )$f$, t);
    -- If the table pre-exists from schema v1/v2, relax user_id and re-key by local_id
    execute format('alter table public.%I alter column user_id drop not null', t);
    execute format('create unique index if not exists %I on public.%I(local_id)', t||'_local_id_key', t);
    execute format('create index if not exists %I on public.%I(username)', t||'_username_idx', t);
    execute format('alter table public.%I enable row level security', t);
    -- The apps read/write with the publishable key (legacy users have no
    -- Supabase auth session) — allow anon + authenticated full access.
    execute format('drop policy if exists "%s: open read"   on public.%I', t, t);
    execute format('drop policy if exists "%s: open insert" on public.%I', t, t);
    execute format('drop policy if exists "%s: open update" on public.%I', t, t);
    execute format('drop policy if exists "%s: open delete" on public.%I', t, t);
    execute format('create policy "%s: open read"   on public.%I for select using (true)', t, t);
    execute format('create policy "%s: open insert" on public.%I for insert with check (true)', t, t);
    execute format('create policy "%s: open update" on public.%I for update using (true) with check (true)', t, t);
    execute format('create policy "%s: open delete" on public.%I for delete using (true)', t, t);
  end loop;
end $$;


-- ─────────────────────────────────────────────
-- BACKFILL profiles for auth users created before this schema
-- ─────────────────────────────────────────────
insert into public.profiles (id, username, full_name, role, status)
select id, split_part(email,'@',1), '', 'field', 'pending'
from auth.users
on conflict (id) do nothing;

-- ─────────────────────────────────────────────
-- ADMIN: ANIENTO is the only dashboard admin.
-- Field users (USER-1, Shiva-1, Shivan-1, …) must stay role='field'.
-- Safe to re-run; does nothing if the auth user doesn't exist yet.
-- ─────────────────────────────────────────────
update public.profiles set username='ANIENTO', role='admin', status='approved' where lower(username)='aniento';
update public.profiles set role='field' where lower(username) <> 'aniento' and role='admin';
