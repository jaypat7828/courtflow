-- CourtFlow — Supabase PostgreSQL schema
-- Run this in the Supabase SQL Editor to create the players table.

create table if not exists public.players (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(trim(name)) > 0),
  created_at  timestamptz not null default now()
);

-- Allow public read and insert (no auth required for MVP)
alter table public.players enable row level security;

create policy "Anyone can read players"
  on public.players for select
  using (true);

create policy "Anyone can insert players"
  on public.players for insert
  with check (true);

create policy "Anyone can delete players"
  on public.players for delete
  using (true);
