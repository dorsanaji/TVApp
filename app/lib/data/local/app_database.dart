import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/enums.dart';

part 'app_database.g.dart';

/// NM-07 — "the user's personal information must be stored locally".
///
/// SQLite via Drift, which §3.1 explicitly sanctions ("a local database such
/// as SQLite or Hive"). Drift is chosen over Hive because the FR-19 statistics
/// are aggregate queries — favourite genre by frequency, total watch time by
/// summing runtimes — and those are a few lines of SQL versus a great deal of
/// hand-rolled Dart.
///
/// **On `userId`.** Accounts arrive in Phase 4. Every table carries a
/// `userId` from the outset, defaulted to [localUser], so adding real accounts
/// is a matter of writing a different value rather than migrating the schema.
/// NFR-38 asks that new capabilities not require a rewrite; this is that
/// principle applied one phase ahead.

const String localUser = 'local';

/// Cached title metadata.
///
/// The watchlist and personal lists must render offline (NFR-20), so enough of
/// each title is stored to draw its card without a network call. This is also
/// what NFR-42 asks for — not re-downloading information already held.
class CachedMedia extends Table {
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  TextColumn get title => text()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get releaseDate => text().nullable()();
  RealColumn get voteAverage => real().nullable()();

  /// Film runtime. Stored so the FR-19 total-watch-time statistic can include
  /// films without re-fetching every title the user has ever marked watched.
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();

  /// Comma-separated genre names, denormalised for the FR-19 favourite-genre
  /// statistic. A join table would be tidier, but this is read far more often
  /// than written and never queried by individual genre.
  TextColumn get genres => text().withDefault(const Constant(''))();

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {mediaId, mediaType};
}

/// FR-09 — the six watch statuses.
class WatchStatuses extends Table {
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  TextColumn get status => textEnum<WatchStatus>()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// One status per title per user. The composite key is what makes
  /// `insertOnConflictUpdate` idempotent, which is how NFR-22 ("recording a
  /// status must not be unintentionally repeated") is guaranteed by the
  /// schema rather than by careful call sites.
  @override
  Set<Column<Object>> get primaryKey => {userId, mediaId, mediaType};
}

/// FR-10 — marked episodes.
class EpisodeWatches extends Table {
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  IntColumn get episodeId => integer()();
  IntColumn get seriesId => integer()();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();

  /// Copied in at mark time so the FR-19 total-watch-time statistic can be
  /// computed without re-fetching every season the user has ever watched.
  IntColumn get runtimeMinutes => integer().withDefault(const Constant(0))();

  DateTimeColumn get watchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId, episodeId};
}

/// Denominator and broadcast state for the FR-11 progress calculation.
///
/// Stored per series so a progress bar can be drawn on a poster in a scrolling
/// list without fetching the series detail for every card — which would defeat
/// NFR-01 and NFR-05 outright.
class SeriesProgressMeta extends Table {
  IntColumn get seriesId => integer()();

  /// Aired episodes only. Unaired episodes are excluded, or a caught-up viewer
  /// could never reach 100%.
  IntColumn get airedEpisodeCount => integer().withDefault(const Constant(0))();

  BoolColumn get hasFinishedAiring =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {seriesId};
}

/// FR-16 — favourites, kept separate from the FR-09 status so a title can be
/// both "in progress" and "favourite" at once, as the brief's two distinct
/// requirements imply.
class Favourites extends Table {
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId, mediaId, mediaType};
}

/// FR-17 — user-created lists.
///
/// The row class is renamed so it does not collide with the domain's
/// `PersonalList`. The database row and the domain entity are different
/// things — one is storage, the other is what the app reasons about — and
/// letting them share a name would blur exactly the boundary NFR-32 asks for.
@DataClassName('PersonalListRow')
class PersonalLists extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ListItems extends Table {
  TextColumn get listId => text().references(PersonalLists, #id)();
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  /// A title cannot appear twice in the same list.
  @override
  Set<Column<Object>> get primaryKey => {listId, mediaId, mediaType};
}

/// FR-01 · FR-04 — accounts.
///
/// NFR-13a: only the derived hash and its salt are stored, never the password.
@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get username => text().unique()();

  /// PBKDF2-HMAC-SHA256 output, hex encoded.
  TextColumn get passwordHash => text()();

  /// Per-user random salt, so two users with the same password do not share a
  /// hash and a precomputed table is useless.
  TextColumn get passwordSalt => text()();

  TextColumn get bio => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('user'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// FR-13 — one rating per user per title, 1–5 stars.
class Ratings extends Table {
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  IntColumn get stars => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// The composite key is what makes re-rating an edit rather than a second
  /// vote — FR-13 requires a user be able to change their previous rating.
  @override
  Set<Column<Object>> get primaryKey => {userId, mediaId, mediaType};
}

/// FR-14 · FR-15 — reviews, with the spoiler flag.
@DataClassName('ReviewRow')
class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUser))();
  IntColumn get mediaId => integer()();
  TextColumn get mediaType => textEnum<MediaType>()();
  TextColumn get body => text()();
  BoolColumn get hasSpoiler => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedMedia,
    WatchStatuses,
    EpisodeWatches,
    SeriesProgressMeta,
    Favourites,
    PersonalLists,
    ListItems,
    Users,
    Ratings,
    Reviews,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cinetrack'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        // Accounts are username-and-password now: there is no address to
        // recover to, so the column and the reset codes both go. Dropping
        // them rather than leaving them unused keeps the schema honest about
        // what the app actually stores about a person.
        await m.alterTable(TableMigration(users));
        await customStatement('DROP TABLE IF EXISTS password_resets');
      }
      if (from < 2) {
        // `status` is stored by name, so rows written before `paused`,
        // `dropped` and `favourite` were retired would fail to parse and take
        // the whole watchlist down with them. Rewrite them instead.
        //
        // A series someone stopped part-way is still one they were watching;
        // a film they never finished goes back to "plan to watch", since a
        // film has no in-progress state. `favourite` was never really a
        // status — the heart of FR-16 lives in its own table — so those rows
        // carry no watch information worth keeping.
        await customStatement(
          "DELETE FROM watch_statuses WHERE status = 'favourite'",
        );
        await customStatement(
          "UPDATE watch_statuses SET status = 'watching' "
          "WHERE status IN ('paused', 'dropped') AND media_type = 'series'",
        );
        await customStatement(
          "UPDATE watch_statuses SET status = 'planToWatch' "
          "WHERE status IN ('paused', 'dropped')",
        );
      }
    },
    beforeOpen: (details) async {
      // Needed for the ListItems → PersonalLists cascade; SQLite leaves
      // foreign keys off by default.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
