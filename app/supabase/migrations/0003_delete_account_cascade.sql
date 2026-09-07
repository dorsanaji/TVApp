-- Deleting an account should delete the person, not just their password.
--
-- Run this in the Supabase SQL editor, after 0002.
--
-- `auth.users` holds credentials; every table the app reads holds `user_id`
-- as plain text with no foreign key back to it. So removing someone under
-- Authentication → Users took away their ability to sign in and left
-- everything else — profile, lists, watch history — in place. The profile row
-- is what the Users tab lists, which is why deleted accounts kept appearing.
--
-- A foreign key would be the usual fix, but `user_id` is text across every
-- table and `auth.users.id` is a uuid; changing the type would break lookups
-- that pass a *username* where an id is expected. A delete trigger achieves
-- the same thing without touching any column type.

-- ── One-off: clear what previous deletions left behind ───────────────────
--
-- Only rows whose account is genuinely gone. Accounts still in auth.users are
-- untouched, so anyone currently signed in keeps their data.

delete from public.public_profiles p
  where not exists (select 1 from auth.users u where u.id::text = p.user_id);

delete from public.watch_statuses t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.episode_watches t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.favourites t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.ratings t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.reviews t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.personal_list_items i
  where not exists (
    select 1 from public.personal_lists l where l.id = i.list_id
  );

delete from public.personal_lists t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.social_activities t
  where not exists (select 1 from auth.users u where u.id::text = t.user_id);

delete from public.user_follows f
  where not exists (select 1 from auth.users u where u.id::text = f.follower_id)
     or not exists (select 1 from auth.users u where u.id::text = f.followed_id);

delete from public.list_collaborators c
  where not exists (select 1 from auth.users u where u.id::text = c.user_id);

delete from public.custom_list_items i
  where not exists (
    select 1 from public.custom_lists l where l.list_id = i.list_id
  );

delete from public.custom_lists t
  where not exists (select 1 from auth.users u where u.id::text = t.owner_id);

-- ── From now on, deleting the account takes the data with it ─────────────

create or replace function public.handle_deleted_account()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Shared lists go whole: their items cascade from custom_lists, and a list
  -- with no owner has nobody who can manage it.
  delete from public.custom_lists      where owner_id    = old.id::text;
  delete from public.list_collaborators where user_id    = old.id::text;

  delete from public.personal_lists    where user_id     = old.id::text;
  delete from public.watch_statuses    where user_id     = old.id::text;
  delete from public.episode_watches   where user_id     = old.id::text;
  delete from public.favourites        where user_id     = old.id::text;
  delete from public.ratings           where user_id     = old.id::text;
  delete from public.reviews           where user_id     = old.id::text;
  delete from public.social_activities where user_id     = old.id::text;
  delete from public.user_follows      where follower_id = old.id::text
                                          or followed_id = old.id::text;
  delete from public.public_profiles   where user_id     = old.id::text;

  return old;
end;
$$;

drop trigger if exists on_auth_user_deleted on auth.users;

create trigger on_auth_user_deleted
  after delete on auth.users
  for each row execute function public.handle_deleted_account();
