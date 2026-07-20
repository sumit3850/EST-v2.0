-- EST v3.0 Supabase Schema — CORRECTED (safe to re-run)
-- Run this entire file in the Supabase SQL Editor
-- Project: fivqdckmtymtuxlhjjoj
--
-- ORDER OF SETUP:
--   1. Create the 3 admin users in Auth > Users > Add user (auto-confirm ON):
--        aniento@est-andaman.in  / 2026
--        shiva-1@est-andaman.in  / 2004
--        shivan-1@est-andaman.in / 1992
--   2. Run this whole file. It creates tables, policies, triggers,
--      backfills profiles for existing auth users, and promotes the admins.

-- ─────────────────────────────────────────────
-- PROFILES TABLE
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text not null unique,
  full_name text default '',
  role text not null default 'field' check (role in ('admin','field')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- ─────────────────────────────────────────────
-- is_admin() — SECURITY DEFINER so policies can check the caller's
-- role without triggering RLS recursion on profiles
-- ─────────────────────────────────────────────
create or replace function public.is_admin()
returns boolean
language sql security definer stable
set search_path = public
as $$
  select exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'approved'
  );
$$;

-- ─────────────────────────────────────────────
-- PROFILES POLICIES
-- ─────────────────────────────────────────────
drop policy if exists "profiles: own read"     on public.profiles;
drop policy if exists "profiles: own update"   on public.profiles;
drop policy if exists "profiles: admin read"   on public.profiles;
drop policy if exists "profiles: admin update" on public.profiles;
drop policy if exists "profiles: insert own"   on public.profiles;

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

-- Prevent non-admins from changing their own role/status
-- (auth.uid() is null when run from the SQL editor / service role — allowed)
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


-- ─────────────────────────────────────────────
-- ADULT SURVEYS TABLE (GPS surveys)
-- ─────────────────────────────────────────────
create table if not exists public.adult_surveys (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  username text not null default '',
  local_id text not null default '',
  data jsonb not null default '{}',
  survey_date text default '',
  location text default '',
  zone text default '',
  district text default '',
  created_at timestamptz default now(),
  unique(local_id, user_id)
);

alter table public.adult_surveys enable row level security;

drop policy if exists "adult_surveys: own read"     on public.adult_surveys;
drop policy if exists "adult_surveys: own insert"   on public.adult_surveys;
drop policy if exists "adult_surveys: own update"   on public.adult_surveys;
drop policy if exists "adult_surveys: own delete"   on public.adult_surveys;
drop policy if exists "adult_surveys: admin read"   on public.adult_surveys;
drop policy if exists "adult_surveys: admin delete" on public.adult_surveys;

create policy "adult_surveys: own read" on public.adult_surveys
  for select using (auth.uid() = user_id);
create policy "adult_surveys: own insert" on public.adult_surveys
  for insert with check (auth.uid() = user_id);
create policy "adult_surveys: own update" on public.adult_surveys
  for update using (auth.uid() = user_id);
create policy "adult_surveys: own delete" on public.adult_surveys
  for delete using (auth.uid() = user_id);
create policy "adult_surveys: admin read" on public.adult_surveys
  for select using (public.is_admin());
create policy "adult_surveys: admin delete" on public.adult_surveys
  for delete using (public.is_admin());


-- ─────────────────────────────────────────────
-- LARVAL SURVEYS TABLE (GPS surveys)
-- ─────────────────────────────────────────────
create table if not exists public.larval_surveys (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  username text not null default '',
  local_id text not null default '',
  data jsonb not null default '{}',
  survey_date text default '',
  location text default '',
  zone text default '',
  district text default '',
  created_at timestamptz default now(),
  unique(local_id, user_id)
);

alter table public.larval_surveys enable row level security;

drop policy if exists "larval_surveys: own read"     on public.larval_surveys;
drop policy if exists "larval_surveys: own insert"   on public.larval_surveys;
drop policy if exists "larval_surveys: own update"   on public.larval_surveys;
drop policy if exists "larval_surveys: own delete"   on public.larval_surveys;
drop policy if exists "larval_surveys: admin read"   on public.larval_surveys;
drop policy if exists "larval_surveys: admin delete" on public.larval_surveys;

create policy "larval_surveys: own read" on public.larval_surveys
  for select using (auth.uid() = user_id);
create policy "larval_surveys: own insert" on public.larval_surveys
  for insert with check (auth.uid() = user_id);
create policy "larval_surveys: own update" on public.larval_surveys
  for update using (auth.uid() = user_id);
create policy "larval_surveys: own delete" on public.larval_surveys
  for delete using (auth.uid() = user_id);
create policy "larval_surveys: admin read" on public.larval_surveys
  for select using (public.is_admin());
create policy "larval_surveys: admin delete" on public.larval_surveys
  for delete using (public.is_admin());


-- ─────────────────────────────────────────────
-- MANUAL ADULT SURVEYS TABLE
-- ─────────────────────────────────────────────
create table if not exists public.manual_adult_surveys (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  username text not null default '',
  local_id text not null default '',
  data jsonb not null default '{}',
  survey_date text default '',
  location text default '',
  zone text default '',
  district text default '',
  created_at timestamptz default now(),
  unique(local_id, user_id)
);

alter table public.manual_adult_surveys enable row level security;

drop policy if exists "manual_adult_surveys: own read"     on public.manual_adult_surveys;
drop policy if exists "manual_adult_surveys: own insert"   on public.manual_adult_surveys;
drop policy if exists "manual_adult_surveys: own update"   on public.manual_adult_surveys;
drop policy if exists "manual_adult_surveys: own delete"   on public.manual_adult_surveys;
drop policy if exists "manual_adult_surveys: admin read"   on public.manual_adult_surveys;
drop policy if exists "manual_adult_surveys: admin delete" on public.manual_adult_surveys;

create policy "manual_adult_surveys: own read" on public.manual_adult_surveys
  for select using (auth.uid() = user_id);
create policy "manual_adult_surveys: own insert" on public.manual_adult_surveys
  for insert with check (auth.uid() = user_id);
create policy "manual_adult_surveys: own update" on public.manual_adult_surveys
  for update using (auth.uid() = user_id);
create policy "manual_adult_surveys: own delete" on public.manual_adult_surveys
  for delete using (auth.uid() = user_id);
create policy "manual_adult_surveys: admin read" on public.manual_adult_surveys
  for select using (public.is_admin());
create policy "manual_adult_surveys: admin delete" on public.manual_adult_surveys
  for delete using (public.is_admin());


-- ─────────────────────────────────────────────
-- MANUAL LARVAL SURVEYS TABLE
-- ─────────────────────────────────────────────
create table if not exists public.manual_larval_surveys (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  username text not null default '',
  local_id text not null default '',
  data jsonb not null default '{}',
  survey_date text default '',
  location text default '',
  zone text default '',
  district text default '',
  created_at timestamptz default now(),
  unique(local_id, user_id)
);

alter table public.manual_larval_surveys enable row level security;

drop policy if exists "manual_larval_surveys: own read"     on public.manual_larval_surveys;
drop policy if exists "manual_larval_surveys: own insert"   on public.manual_larval_surveys;
drop policy if exists "manual_larval_surveys: own update"   on public.manual_larval_surveys;
drop policy if exists "manual_larval_surveys: own delete"   on public.manual_larval_surveys;
drop policy if exists "manual_larval_surveys: admin read"   on public.manual_larval_surveys;
drop policy if exists "manual_larval_surveys: admin delete" on public.manual_larval_surveys;

create policy "manual_larval_surveys: own read" on public.manual_larval_surveys
  for select using (auth.uid() = user_id);
create policy "manual_larval_surveys: own insert" on public.manual_larval_surveys
  for insert with check (auth.uid() = user_id);
create policy "manual_larval_surveys: own update" on public.manual_larval_surveys
  for update using (auth.uid() = user_id);
create policy "manual_larval_surveys: own delete" on public.manual_larval_surveys
  for delete using (auth.uid() = user_id);
create policy "manual_larval_surveys: admin read" on public.manual_larval_surveys
  for select using (public.is_admin());
create policy "manual_larval_surveys: admin delete" on public.manual_larval_surveys
  for delete using (public.is_admin());


-- ─────────────────────────────────────────────
-- TRIGGER: auto-create profile on signup
-- ─────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, full_name, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'full_name',''),
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
-- BACKFILL: create profiles for auth users that existed
-- before this schema was installed
-- ─────────────────────────────────────────────
insert into public.profiles (id, username, full_name, role, status)
select id, split_part(email,'@',1), '', 'field', 'pending'
from auth.users
on conflict (id) do nothing;

-- ─────────────────────────────────────────────
-- PROMOTE ADMINS (matches case-insensitively, fixes display casing)
-- Safe to re-run; does nothing if the auth users don't exist yet.
-- ─────────────────────────────────────────────
update public.profiles set username='ANIENTO',  role='admin', status='approved' where lower(username)='aniento';
update public.profiles set username='Shiva-1',  role='admin', status='approved' where lower(username)='shiva-1';
update public.profiles set username='Shivan-1', role='admin', status='approved' where lower(username)='shivan-1';
