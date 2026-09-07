# هم‌سکانس (Hamsekans) — Technical Summary

**Project:** Movie & series tracking application
**Course:** Mobile Programming (40429), Sharif University of Technology, Department of Computer Engineering
**Package:** `ir.ac.sharif.ce.cinetrack`
**Stack:** Flutter 3.44.9 / Dart 3.12.2, Riverpod 2.6.1, go_router 17.5, Dio 5.11, Supabase 2.17, Drift 2.34
**Report generated:** 2026-09-07, by static scan of the workspace plus live verification against the deployed backend.

> **On the reliability of this document.** Figures for test counts, linter output, file sizes and schema contents were produced by running the tools, not from memory. Statements about defects are separated into those reproduced first-hand during development and those inferred from reading the code; the distinction is marked explicitly in §4. Three items that a reader might otherwise assume are active features are flagged as dead or orphaned code in §6.

---

## 1. Architecture & State Management

### 1.1 Layering

The project follows Clean Architecture with three layers plus a shared kernel. Dependencies point inward only: `features → domain ← data`, with `core` available to all.

| Layer | Path | Files | Lines | Responsibility |
|---|---|---:|---:|---|
| Domain | `lib/domain` | 20 | 1,999 | Entities and repository contracts. No Flutter, no I/O. |
| Data | `lib/data` | 15 | 6,185 | Repository implementations, remote clients, mappers, local schema. |
| Presentation | `lib/features` | 31 | 10,161 | Screens, widgets, Riverpod providers, per-feature actions. |
| Shared kernel | `lib/core` | 29 | 2,716 | DI, error model, networking, theme, l10n, reusable widgets. |
| Routing | `lib/router` | 1 | 263 | `go_router` configuration. |
| **Hand-written total** | | **96** | **21,324** | |
| Generated | `*.g.dart` | — | 6,896 | Drift table/DAO code. |

**Domain layer.** Six repository contracts (`AuthRepository`, `CatalogRepository`, `TrackingRepository`, `ReviewRepository`, `ListRepository`, `SocialRepository`) and thirteen entities, seven of which model the social subsystem (`PublicProfile`, `CustomList`, `CustomListItem`, `ListCollaborator`, `CollaborationRequest`, `SocialActivity`, `ListInviteCode`). Contracts are `abstract interface class`, so implementations cannot inherit behaviour by accident.

**Data layer.** Ten repository implementations. Notably the project carries *two* complete implementations of the personal-data contracts — a Drift/SQLite set (`local_*_repository.dart`) and a Supabase set (`supabase_*_repository.dart`). This is the residue of a mid-project migration from device-local storage to cloud accounts (§2.4); only the Supabase set is bound in the composition root.

**Error handling** is a `Result<T>` sum type (`Ok` / `Err`) rather than exceptions across layer boundaries. Every repository method returns `Future<Result<T>>`, and each implementation wraps its body in a private `_guard` that converts thrown objects into a typed `Failure` via `ErrorMapper`. The failure taxonomy (`NotFoundFailure`, `ValidationFailure`, `UnauthorizedFailure`, `FetchFailure`, `ServiceUnavailableFailure`) maps onto the four error conditions the course brief names, and `ValidationFailure` carries an optional `field` so a form can highlight the offending input rather than showing a detached banner.

### 1.2 Dependency injection and the layering guarantee

`lib/core/di/providers.dart` is the single composition root. Presentation code depends only on abstract types; no widget names a concrete implementation. Swapping the information service means changing one line here.

This property is **enforced mechanically, not merely asserted**. `test/architecture/layering_test.dart` walks the source tree and inspects import statements, failing the build if the dependency direction is violated. `test/core/architecture_seam_test.dart` complements it by binding a fake `CatalogRepository` through the real provider graph, demonstrating the seam works in practice with no network and no database.

### 1.3 State management

Riverpod, used **without code generation**. The reason is recorded in the source: `riverpod_generator` pins `freezed_annotation ^2`, which conflicts with the `^3` that Drift requires. Hand-written providers avoid the version conflict.

**78 provider declarations**, distributed as:

| Kind | Count | Typical use |
|---|---:|---|
| `FutureProvider.family` | 25 | One-shot reads keyed by id (profile, list details, ratings) |
| `Provider` | 20 | DI bindings and derived synchronous state |
| `FutureProvider` | 10 | Global one-shot reads (statistics, followed ids) |
| `FutureProvider.autoDispose.family` | 7 | Server-backed reads that must not outlive their screen |
| `StreamProvider.family` | 4 | Realtime list, items, collaborators, requests |
| `StreamProvider` | 3 | Activity feed, auth state |
| `StateProvider` | 3 | Revision counters, watchlist filter |
| `StateProvider.autoDispose.family` | 2 | Optimistic follow / access-request state |
| `NotifierProvider` | 2 | Search query state |
| `StateProvider.family` | 1 | Per-section watchlist filter |
| `Provider.family` | 1 | Derived pending-request flag |

Three patterns are worth describing for the thesis because each was adopted in response to a specific defect:

**(a) Revision counters as an invalidation bus.** `socialActivityRevisionProvider` and `reviewRevisionProvider` are `StateProvider<int>` counters living in the DI root. Providers that read server state `ref.watch` the counter; any writer increments it. The counters sit in `core/di` specifically so the tracking and social feature layers can both bump them without importing one another — a cyclic import that the layering test would otherwise reject.

**(b) `autoDispose` for anything the server owns.** Non-disposing `FutureProvider.family` caches for the lifetime of the app. Where the underlying rows can change server-side — user search, public profile lists, activity log — this produced stale reads that only cleared on restart. Those providers are now `autoDispose`, so leaving a screen drops the cache.

**(c) Optimistic UI held in a provider, not widget state.** `pendingFollowProvider` and `pendingAccessRequestProvider` hold the state the user asked for before the server confirms it. They are providers rather than `State` fields because two widgets must agree: the follow *button* and the follower *count* are displaying the same fact and have to move together. The optimistic delta cancels itself out automatically once the refreshed profile agrees.

### 1.4 Navigation

`go_router` with a `StatefulShellRoute` carrying five branches — Home, Social, Watchlist, Lists, Profile — each with an independent navigation stack. Auth, search, statistics, public profiles, the diary and collaborative lists are root-level routes presented above the tab bar.

---

## 2. Backend & Database Schema (Supabase)

### 2.1 Identity

Authentication is **Supabase Auth**, reached through `SupabaseAuthRepository`. The design decision worth defending in the thesis is that the application has no email field: users register with a شناسه (username) and password only.

Supabase Auth requires an identifier of email shape, so each account is registered as `<username>@hamsekans.local`. That domain is reserved by RFC 6761 and can never resolve — the address is synthetic, never displayed, never typed, and never receives mail. Consequently the project must run with email confirmation disabled (`mailer_autoconfirm = true`), because a confirmation link sent to an unroutable domain would lock every account out at creation.

The alternative considered and rejected was a hand-rolled `app_users` table holding PBKDF2 hashes. It was rejected on two grounds:

1. The anon key ships inside the APK and is therefore effectively public. Password hashes in a `public` table would be readable by anyone who unzipped the application, and crackable offline.
2. Without Supabase Auth there is no `auth.uid()`, and every row-level policy in the schema compares against it. No policy could distinguish two accounts.

### 2.2 Schema

Fifteen tables across two generations. Six predate the cloud migration and serve the social subsystem; nine were added by `0001_cloud_accounts.sql` to carry per-user data.

**Social subsystem (pre-existing):**

| Table | Primary key | Purpose |
|---|---|---|
| `public_profiles` | `user_id` | Display identity: username, avatar, bio, favourite genre, watch total |
| `user_follows` | (`follower_id`, `followed_id`) | Directed follow graph |
| `custom_lists` | `list_id` | Shared/collaborative lists, with `owner_id`, `is_public`, denormalised `item_count` and `cover_path` |
| `list_collaborators` | (`list_id`, `user_id`) | Accepted collaborators on a shared list |
| `custom_list_items` | `id`, unique (`list_id`,`media_id`,`media_type`) | Titles inside a shared list |
| `social_activities` | `activity_id` | Append-only activity log |

**Per-user data (migration 0001):**

| Table | Primary key | Purpose |
|---|---|---|
| `watch_statuses` | (`user_id`,`media_id`,`media_type`) | FR-09 watch status |
| `episode_watches` | (`user_id`,`episode_id`) | FR-10 episode marks, with runtime for statistics |
| `favourites` | (`user_id`,`media_id`,`media_type`) | FR-16 favourites |
| `ratings` | (`user_id`,`media_id`,`media_type`) | FR-13 star ratings |
| `reviews` | `id` | FR-14 public reviews |
| `personal_lists` | `id` | FR-17 private lists |
| `personal_list_items` | (`list_id`,`media_id`,`media_type`) | Items, FK to `personal_lists` with `on delete cascade` |
| `cached_media` | (`media_id`,`media_type`) | Shared catalogue cache |
| `series_progress_meta` | `series_id` | Aired-episode denominator for progress |

**Relationships.** `user_id` is `text` throughout, holding `auth.uid()::text`. The one true foreign key is `personal_list_items → personal_lists`; all other associations are logical rather than declared, a consequence of `user_id` being text where `auth.users.id` is `uuid`. `cached_media` and `series_progress_meta` are deliberately **not** per-user: a film's title, poster and episode count are identical for everyone, and duplicating them per account would multiply identical rows by the user count.

Two composite-key choices carry design intent. `(user_id, media_id, media_type)` makes writes idempotent by construction — recording the same status twice updates one row rather than inserting a second, satisfying the "must not be unintentionally repeated" requirement at the schema level rather than through careful call sites. Including `media_type` in the key is necessary because TMDB numbers films and series in a shared id space, so a film and a series can legitimately collide on id.

### 2.3 Row-Level Security

RLS is enabled on all nine new tables. Policies fall into three classes:

**Private to owner** — `watch_statuses`, `episode_watches`, `favourites`, `ratings`, `personal_lists`. Generated by a `DO` block that applies the same `FOR ALL` policy to each:

```sql
using (auth.uid()::text = user_id)
with check (auth.uid()::text = user_id)
```

Both clauses are required: `using` governs which rows are visible to read, update and delete; `with check` governs what may be written. Omitting the latter would let an authenticated user insert rows attributed to somebody else.

**Public read, author write** — `reviews`. A review is published under a title, so `select` is granted to `authenticated` and `anon`; insert, update and delete are restricted to `auth.uid()::text = user_id`.

**Shared catalogue** — `cached_media`, `series_progress_meta`. Readable by all, writable by any authenticated user, since the content is objective metadata rather than personal data.

**Derived ownership** — `personal_list_items` has no `user_id` of its own; its policy resolves ownership through an `EXISTS` subquery against the parent list.

The six older social tables predate this work and are **not** under RLS, which is a genuine gap discussed in §6.

### 2.4 Migrations

Three ordered migration files in `supabase/migrations/`. They cannot be applied from the application: the client reaches Postgres through PostgREST, which exposes no DDL endpoint, so each must be run in the Supabase SQL editor.

- **`0001_cloud_accounts.sql`** — the nine tables above, their RLS policies and six indexes.
- **`0002_login_email.sql`** — adds `public_profiles.login_email`. Required because Supabase validates an email *change* more strictly than a signup and rejects the `.local` domain outright (`email_address_invalid`, HTTP 400). The login address is therefore fixed at signup and recorded here, so renaming a شناسه no longer needs to move it.
- **`0003_delete_account_cascade.sql`** — a one-off orphan cleanup plus an `after delete on auth.users` trigger that removes the account's rows from all thirteen data tables. A foreign key would be the conventional mechanism, but `user_id` is `text` against a `uuid` primary key, and converting the column would break lookups that accept a username where an id is expected.

---

## 3. Core Features & Localization

### 3.1 Right-to-left support

Three mechanisms, layered:

**Pinned locale.** `MaterialApp.router` sets `locale: Locale('fa','IR')` with `supportedLocales` containing only that entry, so the interface is Persian even on an English device. `GlobalWidgetsLocalizations.delegate` then resolves the ambient text direction to RTL for the entire tree, which makes `EdgeInsetsDirectional`, `start`/`end` alignment and icon mirroring behave correctly without per-widget handling.

**Bidirectional content resolution.** `lib/core/l10n/bidi_text.dart` addresses a problem the pinned locale creates. TMDB has no Persian synopsis for most titles, so an English paragraph inherits RTL and is laid out against the right margin with its full stop pushed to the *left* of the closing line. `directionOf(String)` counts strong RTL versus strong LTR runes and returns the majority direction, returning `null` for strings containing only digits and punctuation so the ambient direction applies.

This is deliberately *not* the Unicode "first strong character" heuristic: a Persian synopsis opening with a Latin proper noun would be misclassified by first-strong, whereas majority-of-strong keeps it RTL. Arabic-Indic digits are explicitly excluded from the RTL count — Unicode classes them as *Arabic Number* rather than strong right-to-left, so a release year rendered as ۲۰۰۴ should not by itself decide the direction of its line.

**Persian numerals.** `PersianNumbers` provides `toPersianDigits`, `toPersian` (with thousands grouping) and `toPersianPercent`. The distinction matters: a year is an identifier, not a quantity, so `Formatters.jalaliDate` uses plain digit conversion (`۱۳۸۶`) rather than the grouping form (`۱٬۳۸۶`).

**Fonts.** Vazirmatn is bundled at four weights and set on the theme, so nothing can fall back to a Latin face that renders Persian badly. Bundling rather than fetching also means the interface renders correctly with no network.

### 3.2 Jalali (Shamsi) calendar

Backed by `shamsi_date ^1.1.1` for conversion and `persian_datetime_picker ^3.2.0` for input.

- `Formatters.jalaliDate(String? isoDate)` converts a Gregorian ISO date from TMDB — `"2008-01-20"` → `"۳۰ دی ۱۳۸۶"` — falling back to the raw value when unparseable.
- `Formatters.formatJalaliDate(DateTime?)` is the direct-from-`DateTime` form used by the diary.
- `Formatters.relativeTime(DateTime?)` produces Persian relative strings — «همین الان», «۲ ساعت پیش», «۳ روز پیش» — used in the activity feed.

The diary modal (`diary_entry_modal.dart`) uses the Jalali date picker bounded to `Jalali(1370,1,1)` … `Jalali.now()`, so a watch date cannot be set in the future. The chosen date becomes the diary entry's timestamp, which is what the diary sorts and groups by.

### 3.3 TMDB integration

`TmdbApi` wraps Dio over the v3 API with a v4 read token supplied as a compile-time constant through `--dart-define-from-file`, never as a bundled asset (an asset sits in the APK in plain text and can be extracted with `unzip`). Endpoints cover multi-search, person search and combined credits, discover for films and series, detail, season, popular, now-playing, top-rated and recommendations — which is what supports searching by title, director, actor, genre and year.

Three Dio interceptors, all wired in `DioClient.tmdb`:

| Interceptor | Purpose |
|---|---|
| `DedupInterceptor` | Collapses concurrent identical in-flight requests into one |
| `ResponseCacheInterceptor` | Serves a repeat of a recently answered request from memory |
| `RetryInterceptor` | Retries transient failures |

Dedup and cache are shared application-wide via singleton providers, because the saving only counts if every screen draws on the same store.

**Language choice.** `Env.apiLanguage` is pinned to `en-US`, and the reasoning is documented at length in the source. Requesting `fa-IR` looks preferable but TMDB falls back to the *original* language when no Persian translation exists — never to English — producing a list mixing Persian, Korean, Russian and Chinese titles, most unreadable to the intended user. Consistent English is more usable than inconsistent Persian. This does not compromise the Persian-interface requirement, which concerns the chrome: every label, message, date and number the application itself produces is Persian, genres and countries are translated locally by `TmdbLocalization`, and detail screens additionally resolve fa → en → original from the `translations` payload.

### 3.4 Collaborative (shared) lists

Distinct from personal lists: `custom_lists` rows carry an `owner_id`, an `is_public` flag, a collaborator set and a denormalised `item_count`/`cover_path` for cheap rendering.

**Two join paths.**

*Request and accept* — a non-collaborator sends an access request; the owner sees it on the list page and accepts or rejects. Requests are stored as `social_activities` rows with `action_type = 'collab_request'`, `movie_title` holding the list id and `review_text` holding the status. This piggy-backing on an existing table avoided a schema change but is the direct cause of the performance defect in §4.3.

*Invitation code* — for private lists. `ListInviteCode` derives a short human-transcribable code from the list id, so the owner can share it out of band and any number of people can join with it. This required no new table.

Direct addition of a collaborator by username was **removed** during development. It wrote a row keyed to whatever string was typed, so a typo — or a username that resolved to a different account — silently granted edit access to the wrong person. Joining is now one-directional: the joiner initiates, the owner accepts, so whoever ends up on the list is always the person who asked. Owners retain the ability to remove any collaborator, and collaborators can remove themselves.

### 3.5 Diary versus public comments

A design distinction introduced late and worth describing, because the two were originally the same operation. The diary modal called `submitReview` — the identical repository call the public comment box makes — so anything written in the "diary" was published under the film and pushed to friends' feeds.

They are now separate:

| | Diary entry | Public comment |
|---|---|---|
| Storage | `social_activities`, `action_type = 'diary'` | `reviews` table |
| Visible under the film | No | Yes |
| Appears in friends' feed | No — filtered out at the repository | Yes |
| Visible on the author's profile | Yes, dated with stars and note | — |
| Carries a spoiler flag | No — nothing is published | Yes |

The diary field's helper text states the distinction before the user types.

---

## 4. Major Technical Challenges & Debugging

> Items in §4.1–§4.6 were reproduced first-hand: each has a captured error, a measurement, or a failing test that passes after the fix. §4.7 describes hardening that predates the traceable work and is characterised from the code rather than from a reproduction.

### 4.1 Blank-screen layout abort under RTL

**Symptom.** A shared list rendered correctly until another account requested access to it, after which the owner saw an empty page.

**Investigation.** The data layer was exonerated first, by an A/B experiment against the live backend: a list was created, read, a request submitted, and the list re-read. Every repository call returned identical results before and after — `getList`, `getListItems`, `getCollaborators`, `getUserAccessibleLists` and `isCollaborator` — with only the request count moving from 0 to 1. The fault was therefore in rendering.

Reproducing it in a widget test required matching the application's real configuration. Under a default LTR test harness the failure presented as a benign 109-pixel overflow. Under the application's actual RTL configuration the same case produced:

```
BoxConstraints forces an infinite width.
The offending constraints were: BoxConstraints(w=Infinity, 40.0<=h<=Infinity)
The relevant error-causing widget was: FilledButton
RenderBox was not laid out: … (a cascade of ~13 render objects)
Failed assertion: '!childSemantics.renderObject._needsLayout': is not true.
```

**Root cause.** `AppTheme` sets `filledButtonTheme` with `minimumSize: Size.fromHeight(48)`. `Size.fromHeight` produces `Size(double.infinity, 48)` — a *width* of infinity. Inside a `Column` this harmlessly stretches the button to the available width, which is why the pattern went unnoticed across the login, register and other screens. Inside a `Row`, non-flexible children receive unbounded main-axis constraints, so the button was asked to lay out at a tightly infinite width. Layout aborted, the surrounding subtree was never laid out, and nothing painted.

An audit found exactly one `FilledButton` in the codebase that was a direct non-flex child of a `Row`: the «تأیید دسترسی» accept button, which exists only when a pending request exists. That is precisely why the page worked until somebody requested access.

**Resolution.** The button was given an explicit bounded `minimumSize`, both buttons wrapped in `Flexible`, and unconstrained `Text` children given `Expanded`. Six regression tests now render the owner's view in RTL across two screen sizes and two font scales, asserting zero layout errors.

**Thesis value.** The general lesson is that a widget test whose harness differs from the shipping configuration can convert a fatal defect into a cosmetic warning. The RTL direction was not incidental to the bug; it was the difference between a clipped label and a blank screen.

### 4.2 Statistics denominator including unaired episodes

`rememberSeriesProgress` was passed `series.numberOfEpisodes` — TMDB's count of the entire ordered run, including announced but unaired episodes — into a column named and documented as `airedEpisodeCount`. A viewer fully caught up on a running series could therefore never reach 100%.

`Series.airedEpisodeCount` now derives the figure from TMDB's `last_episode_to_air`: every earlier season in full, plus the aired portion of the current season, with specials (season 0) excluded. A finished series short-circuits to its full count. Six unit tests cover part-aired seasons, specials, finished series, announced-but-unaired series, and the missing-season-breakdown fallback.

### 4.3 Realtime stream fetching an entire table

**Symptom.** Shared lists showed prolonged shimmer placeholders on open.

**Measurement.** `watchCollaborationRequests` opened a Supabase realtime stream on `social_activities` with **no server-side filter**, applying the predicate client-side. Measured against the live database, that initial payload was **1,056,235 bytes** — roughly a megabyte, dominated by base64-encoded avatars belonging to other users — fetched every time any shared list was opened, to find at most a handful of relevant rows. Restricting the query to the needed columns reduced the same data to 207,612 bytes.

**Second cause.** The screen watched both the stream provider *and* the one-shot provider for list, items, collaborators and requests. Each `watchX` already performs a direct read and yields it before subscribing, so every query was issued twice on open.

**Resolution.** A server-side `.eq('movie_title', listId)` filter on the stream, explicit column selection instead of `select()`, and one source per datum. The join-request button was additionally made optimistic, since the write plus its re-read is several sequential round trips.

### 4.4 N+1 round trips behind the follow button

The follow button appeared unresponsive, and its state only settled after navigating away and back.

`followUser`, `unfollowUser` and `isFollowing` each resolved *both* user ids through `getProfile`, which additionally runs two follower-count queries irrelevant to id resolution. Combined with the invalidation cascade this put **an estimated 30–50 sequential HTTP requests** behind a single tap.

Three changes: a lightweight `_resolveUserId` that performs a single id lookup; optimistic state shared through a provider so the button and the follower count move together on the tap; and keeping the profile visible during refresh, because falling back to a shimmer on every refetch tore down the button and discarded its optimistic state.

### 4.5 Stale reads from non-disposing providers

Favourites and the diary did not update after being written. The cause was structural rather than a logic error: `userActivitiesProvider`, which feeds both, was a non-`autoDispose` `FutureProvider.family` invalidated only on follow. Writes reached Supabase but nothing told the provider, and the cache persisted for the lifetime of the process, so only an application restart reflected them.

Resolved with the revision-counter bus described in §1.3(a) plus `autoDispose`. The same class of defect recurred twice more — in the user-search tab and in profile list counts — and was fixed the same way each time.

### 4.6 Two defects found while fixing others

Worth recording because both were latent and would have been hard to attribute later.

**Duplicate diary entries.** The diary modal used `activityId: 'act_${DateTime.now().microsecondsSinceEpoch}'`, so re-saving an entry inserted a new row rather than updating. Live data confirmed nine such rows with genuine duplicates. Activity ids are now deterministic, keyed to user, action and title.

**Media type lost in activity ids.** Films and series share TMDB's id space and `social_activities` has no column for type, so every activity poster navigated to `/movie/<id>` — sending a favourited *series* to a film with the same number. The type is now encoded in the activity id and parsed back on read.

### 4.7 Defensive null handling in image loading

`PosterCard`, `UserAvatar` and `Env.imageUrl` share a validation idiom applied before any image is constructed:

```dart
final valid = raw != null && raw.trim().isNotEmpty && raw.trim() != 'null';
```

The literal string `'null'` is checked explicitly, which indicates the upstream defect this guards against: a null poster path stringified somewhere in the pipeline and stored as the four characters `null`, which is truthy and non-empty and would otherwise be concatenated into a request URL. `resolveAvatarProvider` handles three source shapes — HTTP URL, base64 `data:` URI and local file path — returning `null` rather than throwing for anything unrecognised, and `_Fallback` renders the title's first character when no image can be produced.

`test/widget/find_null_check_crash_test.dart` exercises the owner and non-owner rendering paths that these guards protect.

**Attribution note.** This hardening predates the traceable development history available to this report — the repository's history is a single squashed commit — so it is described from the code rather than from a reproduction. A thesis should present it as a defensive pattern present in the codebase, not as a defect diagnosed with a captured stack trace, unless the author has independent records of the original crash.

---

## 5. Testing & QA Status

### 5.1 Results

```
$ flutter analyze
Analyzing app...
No issues found!

$ flutter test --dart-define-from-file=dart_defines.json
00:13 +247: All tests passed!
```

**247 tests across 37 files, all passing. Linter clean** under `analysis_options.yaml`, which enables `flutter_lints` plus roughly forty additional rules including `avoid_dynamic_calls`, `prefer_const_constructors`, `directives_ordering` and `use_null_aware_elements`.

### 5.2 Composition

| Category | Files | Focus |
|---|---:|---|
| Architecture | 2 | Import-direction enforcement; DI seam with a fake repository |
| Core / infrastructure | 4 | Dedup and response-cache interceptors, error mapping, Persian formatting |
| Data / repository | 10 | Auth, tracking, reviews, social, user isolation, TMDB client and mapper, watch-status rules, shared-list covers, diary privacy |
| Domain / pure logic | 7 | Watch progress, aired-episode count, rating summary, social models, diary dedupe, invite codes, activity media type |
| Widget | 14 | Layout regression, RTL bidi text, status picker, watchlist sections, diary modal, social screens, collaborative-list rendering, statistics |

### 5.3 Notable properties under test

- **Architectural constraints** are executable. The layering test fails the build on a violation, so NFR-30/32/33 cannot quietly rot as the codebase grows.
- **User isolation** — `user_isolation_test.dart` verifies that switching accounts does not leak one user's tracked data into another's view.
- **Idempotency** — repeated writes are asserted to produce one row, not several.
- **RTL layout regression** — the §4.1 defect is covered across two screen sizes and two font scales, in the application's real RTL configuration rather than a default LTR harness.
- **Privacy invariants** — `diary_is_private_test.dart` asserts a diary entry publishes no review under the title and never reaches the friends feed.

### 5.4 Known gaps in coverage

Stated plainly, because a thesis should not overclaim:

- **No integration or end-to-end tests** run in CI. Cross-device account behaviour was verified once, manually, by registering through one client and reading back through a second with separate storage; that probe was then deleted rather than kept as a fixture, since it wrote to the production database.
- **Two tests were deleted** during the cloud migration rather than ported: `provider_account_switch_test.dart` (exercised Drift-backed account switching, which no longer exists) and `render_all_real_lists_test.dart` (rendered against hard-coded live list ids, and never reached the network under `flutter test`, so it was passing vacuously).
- **The Supabase repositories are not unit-tested** against a fake PostgREST. Their offline branches are covered via `client: null`; the network branches are not.
- **Widget tests use fakes for auth and tracking** (`test/support/fake_auth.dart`), so they verify screen behaviour rather than integration with Supabase.

---

## 6. Known Issues and Dead Code

Included so the thesis does not describe capabilities the code does not have.

**`CertificatePinning` is defined but never referenced.** `lib/core/network/certificate_pinning.dart` declares the class, but no call site wires it into the Dio client. TLS is therefore standard platform trust, not pinned. This should not be presented as an implemented security control.

**Drift/SQLite is orphaned.** `databaseProvider` is still declared in the composition root but is read by nothing after the cloud migration. `AppDatabase`, its 6,896 lines of generated code, and the four `local_*_repository.dart` implementations are dead relative to the running application. They remain useful as evidence of the pre-migration architecture but are not exercised.

**Offline capability was lost in the migration.** Watch history, lists and ratings are now remote, so the application requires connectivity. The previous local-first design rendered the watchlist offline. This is an inherent consequence of cross-device accounts and should be presented as a deliberate trade-off rather than an oversight.

**The six older social tables have no RLS.** `public_profiles`, `user_follows`, `custom_lists`, `list_collaborators`, `custom_list_items` and `social_activities` are readable and writable with the anon key. Since that key ships in the APK, any client can modify another user's social rows. The nine tables added by migration 0001 are protected; extending equivalent policies to the older six is the most significant outstanding security task.

**Migration 0002 is unapplied at time of writing**, so changing a شناسه is refused with an explanatory message. The refusal is deliberate: without the login address on record, a rename would succeed and then lock the account out, because sign-in would derive an address from the new name and find nothing.

**Orphaned collaboration requests.** Requests stored in `social_activities` are not cascade-deleted with their list, so rows referencing deleted lists accumulate.
