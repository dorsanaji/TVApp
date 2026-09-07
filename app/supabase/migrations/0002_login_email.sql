-- Lets a user change their شناسه.
--
-- Run this in the Supabase SQL editor, after 0001.
--
-- Supabase Auth needs an address per account, and the app derived it from the
-- username: `<username>@hamsekans.local`. That worked until someone renamed
-- themselves — moving the address with the name means calling
-- `auth.updateUser(email:)`, and Supabase validates an email *change* more
-- strictly than a signup, rejecting the unroutable `.local` domain outright:
--
--   AuthApiException: Email address "…@hamsekans.local" is invalid
--   statusCode: 400, code: email_address_invalid
--
-- So the address has to stop tracking the name. It is fixed at signup and
-- never changes; this column remembers it, so signing in can still start from
-- the username the user actually types. Rows written before this column
-- existed leave it null, and those accounts fall back to the old derivation —
-- correct for them, because they have never been renamed.

alter table public.public_profiles
  add column if not exists login_email text;

-- Sign-in reads this by username before the user has a session, so it has to
-- be selectable by anon. It holds no secret: the addresses are synthetic, and
-- the password is what protects the account.
create index if not exists public_profiles_username_idx
  on public.public_profiles (lower(username));
