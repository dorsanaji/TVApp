/// Constants for Supabase tables and column names, along with the
/// SQL migration script needed to set up Supabase Postgres schema.
abstract final class SupabaseTables {
  const SupabaseTables._();

  static const String publicProfiles = 'public_profiles';
  static const String userFollows = 'user_follows';
  static const String customLists = 'custom_lists';
  static const String listCollaborators = 'list_collaborators';
  static const String customListItems = 'custom_list_items';
  static const String socialActivities = 'social_activities';

  /// SQL schema to run in Supabase SQL editor:
  /// ```sql
  /// -- 1. Public Profiles
  /// create table if not exists public.public_profiles (
  ///   user_id text primary key,
  ///   username text unique not null,
  ///   avatar_url text,
  ///   bio text,
  ///   total_watched integer default 0,
  ///   favorite_genre text,
  ///   created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  ///   updated_at timestamp with time zone default timezone('utc'::text, now()) not null
  /// );
  ///
  /// -- 2. Follows
  /// create table if not exists public.user_follows (
  ///   follower_id text not null,
  ///   followed_id text not null,
  ///   created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  ///   primary key (follower_id, followed_id)
  /// );
  ///
  /// -- 3. Custom Collaborative Lists
  /// create table if not exists public.custom_lists (
  ///   list_id text primary key,
  ///   owner_id text not null,
  ///   title text not null,
  ///   description text,
  ///   is_public boolean default true,
  ///   cover_path text,
  ///   item_count integer default 0,
  ///   created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  ///   updated_at timestamp with time zone default timezone('utc'::text, now()) not null
  /// );
  ///
  /// -- 4. List Collaborators
  /// create table if not exists public.list_collaborators (
  ///   list_id text references public.custom_lists(list_id) on delete cascade,
  ///   user_id text not null,
  ///   username text,
  ///   avatar_url text,
  ///   added_at timestamp with time zone default timezone('utc'::text, now()) not null,
  ///   primary key (list_id, user_id)
  /// );
  ///
  /// -- 5. Custom List Items
  /// create table if not exists public.custom_list_items (
  ///   id text primary key,
  ///   list_id text references public.custom_lists(list_id) on delete cascade,
  ///   media_id integer not null,
  ///   media_type text not null,
  ///   title text not null,
  ///   poster_path text,
  ///   overview text,
  ///   release_date text,
  ///   vote_average double precision,
  ///   added_by text not null,
  ///   added_at timestamp with time zone default timezone('utc'::text, now()) not null,
  ///   unique (list_id, media_id, media_type)
  /// );
  ///
  /// -- 6. Social Activities
  /// create table if not exists public.social_activities (
  ///   activity_id text primary key,
  ///   user_id text not null,
  ///   action_type text not null,
  ///   movie_id integer not null,
  ///   movie_title text,
  ///   movie_poster text,
  ///   username text,
  ///   user_avatar text,
  ///   rating double precision,
  ///   review_text text,
  ///   list_title text,
  ///   created_at timestamp with time zone default timezone('utc'::text, now()) not null
  /// );
  ///
  /// -- Enable Realtime Publication
  /// alter publication supabase_realtime add table public.public_profiles;
  /// alter publication supabase_realtime add table public.custom_lists;
  /// alter publication supabase_realtime add table public.list_collaborators;
  /// alter publication supabase_realtime add table public.custom_list_items;
  /// alter publication supabase_realtime add table public.social_activities;
  /// ```
  static const String sqlSchema = '-- Run in Supabase SQL editor';
}
