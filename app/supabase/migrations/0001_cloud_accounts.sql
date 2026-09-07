-- هم‌سکانس — cloud accounts and per-user data.
--
-- Run this once in the Supabase SQL editor. It cannot be applied from the
-- app: the client talks to Postgres through PostgREST, which exposes no DDL.
--
-- BEFORE RUNNING, in Authentication → Providers → Email:
--   • turn "Confirm email" OFF (autoconfirm)
-- Accounts are username-only, so the app registers each user as
-- <username>@hamsekans.local. That address is never shown and never receives
-- mail, so a confirmation step would lock every account out permanently.
--
-- Identity is Supabase Auth. `auth.uid()` is the user, and every policy below
-- compares against it, so one account cannot read or write another's rows —
-- which a hand-rolled users table could not guarantee, because the anon key
-- ships inside the APK and is effectively public.
--
-- `user_id` is text holding `auth.uid()::text`, matching the existing social
-- tables rather than introducing a second convention.

-- ── Per-user tracking ────────────────────────────────────────────────────

create table if not exists public.watch_statuses (
  user_id     text not null,
  media_id    integer not null,
  media_type  text not null,
  status      text not null,
  updated_at  timestamptz not null default now(),
  primary key (user_id, media_id, media_type)
);

create table if not exists public.episode_watches (
  user_id         text not null,
  episode_id      integer not null,
  series_id       integer not null,
  season_number   integer not null default 0,
  episode_number  integer not null default 0,
  runtime_minutes integer not null default 0,
  watched_at      timestamptz not null default now(),
  primary key (user_id, episode_id)
);

create table if not exists public.favourites (
  user_id    text not null,
  media_id   integer not null,
  media_type text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, media_id, media_type)
);

create table if not exists public.ratings (
  user_id    text not null,
  media_id   integer not null,
  media_type text not null,
  stars      integer not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, media_id, media_type)
);

create table if not exists public.reviews (
  id          text primary key,
  user_id     text not null,
  media_id    integer not null,
  media_type  text not null,
  body        text not null,
  has_spoiler boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz
);

-- ── Personal lists (FR-17), distinct from the shared custom_lists ────────

create table if not exists public.personal_lists (
  id          text primary key,
  user_id     text not null,
  name        text not null,
  description text,
  created_at  timestamptz not null default now()
);

create table if not exists public.personal_list_items (
  list_id    text not null references public.personal_lists(id) on delete cascade,
  media_id   integer not null,
  media_type text not null,
  position   integer not null default 0,
  added_at   timestamptz not null default now(),
  primary key (list_id, media_id, media_type)
);

-- ── Shared catalogue cache ───────────────────────────────────────────────
--
-- Not per-user: a film's title and poster are the same for everyone, and
-- copying them per account would multiply the same rows by the user count.
-- Readable by all, writable by any signed-in user.

create table if not exists public.cached_media (
  media_id        integer not null,
  media_type      text not null,
  title           text not null,
  poster_path     text,
  overview        text,
  release_date    text,
  vote_average    double precision,
  runtime_minutes integer not null default 0,
  genres          text not null default '',
  cached_at       timestamptz not null default now(),
  primary key (media_id, media_type)
);

-- Denominator for the FR-11 progress bar. Also per-title, not per-user.
create table if not exists public.series_progress_meta (
  series_id           integer primary key,
  aired_episode_count integer not null default 0,
  has_finished_airing boolean not null default false,
  updated_at          timestamptz not null default now()
);

-- ── Row level security ───────────────────────────────────────────────────

alter table public.watch_statuses      enable row level security;
alter table public.episode_watches     enable row level security;
alter table public.favourites          enable row level security;
alter table public.ratings             enable row level security;
alter table public.reviews             enable row level security;
alter table public.personal_lists      enable row level security;
alter table public.personal_list_items enable row level security;
alter table public.cached_media        enable row level security;
alter table public.series_progress_meta enable row level security;

-- Private to their owner: nobody else's business what you plan to watch.
do $$
declare t text;
begin
  foreach t in array array[
    'watch_statuses', 'episode_watches', 'favourites',
    'ratings', 'personal_lists'
  ]
  loop
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (auth.uid()::text = user_id)
         with check (auth.uid()::text = user_id)', t || '_own', t);
  end loop;
end $$;

-- Reviews are published under a title, so anyone may read them; only the
-- author may write.
create policy reviews_read on public.reviews
  for select to authenticated, anon using (true);
create policy reviews_write on public.reviews
  for insert to authenticated with check (auth.uid()::text = user_id);
create policy reviews_update on public.reviews
  for update to authenticated using (auth.uid()::text = user_id);
create policy reviews_delete on public.reviews
  for delete to authenticated using (auth.uid()::text = user_id);

-- List items follow their list's owner.
create policy personal_list_items_own on public.personal_list_items
  for all to authenticated
  using (
    exists (
      select 1 from public.personal_lists l
      where l.id = list_id and l.user_id = auth.uid()::text
    )
  )
  with check (
    exists (
      select 1 from public.personal_lists l
      where l.id = list_id and l.user_id = auth.uid()::text
    )
  );

-- Shared catalogue data: everyone reads, signed-in users fill it in.
create policy cached_media_read on public.cached_media
  for select to authenticated, anon using (true);
create policy cached_media_write on public.cached_media
  for all to authenticated using (true) with check (true);

create policy series_progress_read on public.series_progress_meta
  for select to authenticated, anon using (true);
create policy series_progress_write on public.series_progress_meta
  for all to authenticated using (true) with check (true);

-- ── Helpful indexes ──────────────────────────────────────────────────────

create index if not exists watch_statuses_user_idx on public.watch_statuses (user_id);
create index if not exists episode_watches_series_idx on public.episode_watches (user_id, series_id);
create index if not exists favourites_user_idx on public.favourites (user_id);
create index if not exists ratings_media_idx on public.ratings (media_id, media_type);
create index if not exists reviews_media_idx on public.reviews (media_id, media_type);
create index if not exists personal_lists_user_idx on public.personal_lists (user_id);
