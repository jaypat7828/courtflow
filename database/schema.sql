-- ============================================================
-- CourtFlow — Supabase PostgreSQL schema
-- Run the entire file in the Supabase SQL Editor.
-- Auth (email + password) is handled by Supabase built-in auth.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Profiles
--    One row per auth user — stores display name.
--    Created automatically via trigger on new sign-up.
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null check (char_length(trim(username)) > 0),
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row when a new user signs up.
-- The username defaults to the email prefix until the user changes it.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    split_part(new.email, '@', 1)
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- 2. Players
--    Scoped to the owning user via user_id.
--    Each user manages their own player roster.
-- ------------------------------------------------------------

-- Drop old open policies if re-running this script
drop policy if exists "Anyone can read players"   on public.players;
drop policy if exists "Anyone can insert players"  on public.players;
drop policy if exists "Anyone can delete players"  on public.players;

-- Add user_id column (safe to run on existing table)
alter table public.players
  add column if not exists user_id uuid references auth.users (id) on delete cascade;

-- Tighten RLS: each user sees only their own players
create policy "Users can read own players"
  on public.players for select
  using (auth.uid() = user_id);

create policy "Users can insert own players"
  on public.players for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own players"
  on public.players for delete
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 3. Tournaments  (stub — ready for Phase 6)
-- ------------------------------------------------------------
create table if not exists public.tournaments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  name        text not null check (char_length(trim(name)) > 0),
  date        date,
  created_at  timestamptz not null default now()
);

alter table public.tournaments enable row level security;

create policy "Users can read own tournaments"
  on public.tournaments for select
  using (auth.uid() = user_id);

create policy "Users can insert own tournaments"
  on public.tournaments for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own tournaments"
  on public.tournaments for delete
  using (auth.uid() = user_id);

