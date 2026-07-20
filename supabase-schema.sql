-- EST v3.0 Supabase Schema
-- Run this entire file in the Supabase SQL Editor
-- Project: fivqdckmtymtuxlhjjoj

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

-- Users can read/update their own profile
create policy "profiles: own read" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles: own update" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Admins can read and update all profiles
create policy "profiles: admin read" on public.profiles
  for select using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );
create policy "profiles: admin update" on public.profiles
  for update using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );

-- Allow insert on own profile (during registration)
create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);


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

create policy "adult_surveys: own read" on public.adult_surveys
  for select using (auth.uid() = user_id);
create policy "adult_surveys: own insert" on public.adult_surveys
  for insert with check (auth.uid() = user_id);
create policy "adult_surveys: own update" on public.adult_surveys
  for update using (auth.uid() = user_id);
create policy "adult_surveys: own delete" on public.adult_surveys
  for delete using (auth.uid() = user_id);

-- Admins can read all
create policy "adult_surveys: admin read" on public.adult_surveys
  for select using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );
create policy "adult_surveys: admin delete" on public.adult_surveys
  for delete using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );


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

create policy "larval_surveys: own read" on public.larval_surveys
  for select using (auth.uid() = user_id);
create policy "larval_surveys: own insert" on public.larval_surveys
  for insert with check (auth.uid() = user_id);
create policy "larval_surveys: own update" on public.larval_surveys
  for update using (auth.uid() = user_id);
create policy "larval_surveys: own delete" on public.larval_surveys
  for delete using (auth.uid() = user_id);

create policy "larval_surveys: admin read" on public.larval_surveys
  for select using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );
create policy "larval_surveys: admin delete" on public.larval_surveys
  for delete using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );


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

create policy "manual_adult_surveys: own read" on public.manual_adult_surveys
  for select using (auth.uid() = user_id);
create policy "manual_adult_surveys: own insert" on public.manual_adult_surveys
  for insert with check (auth.uid() = user_id);
create policy "manual_adult_surveys: own update" on public.manual_adult_surveys
  for update using (auth.uid() = user_id);
create policy "manual_adult_surveys: own delete" on public.manual_adult_surveys
  for delete using (auth.uid() = user_id);

create policy "manual_adult_surveys: admin read" on public.manual_adult_surveys
  for select using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );
create policy "manual_adult_surveys: admin delete" on public.manual_adult_surveys
  for delete using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );


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

create policy "manual_larval_surveys: own read" on public.manual_larval_surveys
  for select using (auth.uid() = user_id);
create policy "manual_larval_surveys: own insert" on public.manual_larval_surveys
  for insert with check (auth.uid() = user_id);
create policy "manual_larval_surveys: own update" on public.manual_larval_surveys
  for update using (auth.uid() = user_id);
create policy "manual_larval_surveys: own delete" on public.manual_larval_surveys
  for delete using (auth.uid() = user_id);

create policy "manual_larval_surveys: admin read" on public.manual_larval_surveys
  for select using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );
create policy "manual_larval_surveys: admin delete" on public.manual_larval_surveys
  for delete using (
    exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin' and p.status = 'approved')
  );


-- ─────────────────────────────────────────────
-- TRIGGER: auto-create profile on signup
-- Runs as SECURITY DEFINER so it can insert into profiles
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
-- SEED ADMIN USERS (optional)
-- Run manually via Supabase Auth > Users > Invite
-- or use the Auth API to create:
--   email: aniento@est-andaman.in  password: 2026  role: admin
--   email: shiva-1@est-andaman.in  password: 2004  role: admin
--   email: shivan-1@est-andaman.in password: 1992  role: admin
-- Then update their profiles:
-- ─────────────────────────────────────────────
-- update public.profiles set role='admin', status='approved' where username in ('ANIENTO','Shiva-1','Shivan-1');
