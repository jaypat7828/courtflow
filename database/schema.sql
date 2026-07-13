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
  id                uuid primary key references auth.users (id) on delete cascade,
  username          text not null check (char_length(trim(username)) > 0),
  email_verified_at timestamptz,          -- null = not yet verified via our queue
  created_at        timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row when a new user signs up.
-- Uses username from signup metadata if provided, otherwise falls back to email prefix.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'username'), ''),
      split_part(new.email, '@', 1)
    )
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

-- ------------------------------------------------------------
-- 4. Email Queue
--    Stores outgoing confirmation emails to be sent in batches.
--    Processed by a Supabase Edge Function (max 3/hour to stay
--    within Supabase free-tier rate limits).
-- ------------------------------------------------------------
create table if not exists public.email_queue (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  email              text not null,
  type               text not null default 'email_confirmation',
  verification_token uuid not null default gen_random_uuid(), -- included in the email link
  created_at         timestamptz not null default now(),
  scheduled_at       timestamptz not null default now(),
  sent_at            timestamptz,
  error              text
);

-- Only the service role (Edge Function) can read/update this table.
-- Users can insert their own queued email.
alter table public.email_queue enable row level security;

create policy "Users can queue own confirmation email"
  on public.email_queue for insert
  with check (auth.uid() = user_id);

create policy "Users can view own email queue"
  on public.email_queue for select
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 5. verify_email RPC
--    Called when user clicks the link in the confirmation email.
--    Matches the token, marks profiles.email_verified_at.
-- ------------------------------------------------------------
create or replace function public.verify_email(token uuid)
returns boolean
language plpgsql security definer
as $$
declare
  v_user_id uuid;
begin
  -- Find the queued email with this token that hasn't expired (7 days)
  select user_id into v_user_id
  from public.email_queue
  where verification_token = token
    and sent_at is not null
    and created_at > now() - interval '7 days'
  limit 1;

  if v_user_id is null then
    return false;
  end if;

  -- Mark the profile as verified
  update public.profiles
  set email_verified_at = now()
  where id = v_user_id;

  return true;
end;
$$;

-- ------------------------------------------------------------
-- 6. pg_cron schedule (run once after enabling the extension)
--    Supabase Dashboard → Database → Extensions → enable pg_cron
--    Then run this once in the SQL editor:
--
--  select cron.schedule(
--    'process-email-queue',
--    '*/20 * * * *',   -- every 20 minutes
--    $$
--      select net.http_post(
--        url := current_setting('app.edge_function_url') || '/process-email-queue',
--        headers := jsonb_build_object(
--          'Content-Type', 'application/json',
--          'Authorization', 'Bearer ' || current_setting('app.service_role_key')
--        ),
--        body := '{}'::jsonb
--      );
--    $$
--  );
-- ------------------------------------------------------------

