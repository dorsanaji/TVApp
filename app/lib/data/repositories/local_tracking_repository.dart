import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/entities/watch_progress.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../local/app_database.dart';

/// [TrackingRepository] backed by the local database (§3.1, NM-07).
///
/// Every write is an upsert on a composite primary key, so repeating one is a
/// no-op rather than a duplicate — NFR-22 ("recording a rating, review, or
/// watching status must not be unintentionally repeated") is enforced by the
/// schema, not by discipline at the call sites.
class LocalTrackingRepository implements TrackingRepository {
  LocalTrackingRepository(this._db, this._auth) {
    // Signing in or out changes which rows are visible just as surely as
    // writing one does, so it emits on the same stream. Without this the
    // screens kept showing the previous account's data — a favourite stayed
    // lit after logout, because nothing told the UI to look again.
    _authSubscription = _auth.currentUser.listen((_) => _notify());
  }

  StreamSubscription<AppUser?>? _authSubscription;

  final AppDatabase _db;
  final AuthRepository _auth;

  /// The row owner for every read and write.
  ///
  /// **This must never be a constant.** Scoping to a fixed `'local'` value was
  /// a real defect: a freshly registered account inherited the previous
  /// account's watch statuses, favourites and lists, because every row was
  /// filed under the same owner. That is both wrong and a breach of NFR-16
  /// ("users must only have access to their own permitted information").
  ///
  /// Guests fall back to [localUser], which keeps browsing-before-signup
  /// working while still isolating it from every real account.
  String get _userId => _auth.currentUserOrNull?.id ?? localUser;

  /// The owner for a **write**, refusing guests.
  ///
  /// §4.1: "برای ثبت فعالیت، امتیاز، نظر و فهرست شخصی، ثبت‌نام و ورود به سیستم
  /// الزامی است" — registration and login are mandatory for recording activity.
  /// Reads stay open so a guest can browse (which §4.1 explicitly allows);
  /// only recording is gated.
  String _requireUserId() {
    final id = _auth.currentUserOrNull?.id;
    if (id == null) throw const UnauthorizedFailure();
    return id;
  }

  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } catch (e, stack) {
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  // ── FR-09 · Watch status ──────────────────────────────────────────────

  @override
  Future<Result<WatchStatus?>> statusOf(int id, MediaType type) {
    return _guard(() async {
      final row =
          await (_db.select(_db.watchStatuses)..where(
                (t) =>
                    t.userId.equals(_userId) &
                    t.mediaId.equals(id) &
                    t.mediaType.equalsValue(type),
              ))
              .getSingleOrNull();
      return row?.status;
    });
  }

  @override
  Future<Result<void>> setStatus(int id, MediaType type, WatchStatus? status) {
    return _guard(() async {
      _requireUserId();
      if (status == null) {
        await (_db.delete(_db.watchStatuses)..where(
              (t) =>
                  t.userId.equals(_userId) &
                  t.mediaId.equals(id) &
                  t.mediaType.equalsValue(type),
            ))
            .go();
      } else {
        await _db
            .into(_db.watchStatuses)
            .insertOnConflictUpdate(
              WatchStatusesCompanion.insert(
                userId: Value(_userId),
                mediaId: id,
                mediaType: type,
                status: status,
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
      _notify();
    });
  }

  // ── FR-10 · Episode marks ─────────────────────────────────────────────

  @override
  Future<Result<Set<int>>> watchedEpisodeIds(int seriesId) {
    return _guard(() async {
      final rows =
          await (_db.select(_db.episodeWatches)..where(
                (t) => t.userId.equals(_userId) & t.seriesId.equals(seriesId),
              ))
              .get();
      return rows.map((r) => r.episodeId).toSet();
    });
  }

  @override
  Future<Result<void>> setEpisodeWatched(
    int seriesId,
    int episodeId, {
    required bool watched,
    int seasonNumber = 0,
    int episodeNumber = 0,
    int runtimeMinutes = 0,
  }) {
    return _guard(() async {
      _requireUserId();
      if (watched) {
        await _db
            .into(_db.episodeWatches)
            .insertOnConflictUpdate(
              EpisodeWatchesCompanion.insert(
                userId: Value(_userId),
                episodeId: episodeId,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                runtimeMinutes: Value(runtimeMinutes),
              ),
            );
      } else {
        await (_db.delete(_db.episodeWatches)..where(
              (t) => t.userId.equals(_userId) & t.episodeId.equals(episodeId),
            ))
            .go();
      }
      _notify();
    });
  }

  @override
  Future<Result<void>> setSeasonWatched(
    int seriesId,
    int seasonNumber,
    List<int> episodeIds, {
    required bool watched,
    Map<int, int> runtimes = const {},
    Map<int, int> episodeNumbers = const {},
  }) {
    return _guard(() async {
      _requireUserId();
      // One transaction for the whole season: marking 24 episodes must be a
      // single atomic act, or an interruption leaves the progress bar wrong.
      await _db.transaction(() async {
        if (watched) {
          await _db.batch((batch) {
            batch.insertAllOnConflictUpdate(_db.episodeWatches, [
              for (final id in episodeIds)
                EpisodeWatchesCompanion.insert(
                  userId: Value(_userId),
                  episodeId: id,
                  seriesId: seriesId,
                  seasonNumber: seasonNumber,
                  episodeNumber: episodeNumbers[id] ?? 0,
                  runtimeMinutes: Value(runtimes[id] ?? 0),
                ),
            ]);
          });
        } else {
          await (_db.delete(_db.episodeWatches)..where(
                (t) => t.userId.equals(_userId) & t.episodeId.isIn(episodeIds),
              ))
              .go();
        }
      });
      _notify();
    });
  }

  // ── FR-11 · Progress ──────────────────────────────────────────────────

  @override
  Future<Result<WatchProgress>> progressOf(int seriesId) async {
    final result = await progressForAll([seriesId]);
    return result.map((byId) => byId[seriesId] ?? const WatchProgress.empty());
  }

  @override
  Future<Result<Map<int, WatchProgress>>> progressForAll(List<int> seriesIds) {
    return _guard(() async {
      if (seriesIds.isEmpty) return <int, WatchProgress>{};

      // Three set-based queries rather than three per series. A watchlist of
      // 50 shows would otherwise be 150 round trips to SQLite (NFR-01).
      final watchedCounts = await _watchedCountsFor(seriesIds);
      final meta = await (_db.select(
        _db.seriesProgressMeta,
      )..where((t) => t.seriesId.isIn(seriesIds))).get();
      final statuses =
          await (_db.select(_db.watchStatuses)..where(
                (t) =>
                    t.userId.equals(_userId) &
                    t.mediaType.equalsValue(MediaType.series) &
                    t.mediaId.isIn(seriesIds),
              ))
              .get();

      final metaById = {for (final m in meta) m.seriesId: m};
      final statusById = {for (final s in statuses) s.mediaId: s.status};

      return {
        for (final id in seriesIds)
          id: WatchProgress(
            watchedEpisodes: watchedCounts[id] ?? 0,
            totalEpisodes: metaById[id]?.airedEpisodeCount ?? 0,
            hasFinishedAiring: metaById[id]?.hasFinishedAiring ?? false,
            userStatus: statusById[id],
          ),
      };
    });
  }

  Future<Map<int, int>> _watchedCountsFor(List<int> seriesIds) async {
    final count = _db.episodeWatches.episodeId.count();
    final query = _db.selectOnly(_db.episodeWatches)
      ..addColumns([_db.episodeWatches.seriesId, count])
      ..where(
        _db.episodeWatches.userId.equals(_userId) &
            _db.episodeWatches.seriesId.isIn(seriesIds),
      )
      ..groupBy([_db.episodeWatches.seriesId]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.episodeWatches.seriesId)!: row.read(count) ?? 0,
    };
  }

  // ── FR-12 · Watchlist ─────────────────────────────────────────────────

  @override
  Future<Result<List<MediaSummary>>> watchlist(WatchlistSection section) {
    return _guard(() async {
      if (section == WatchlistSection.favourites) {
        return _summariesFromFavourites();
      }

      final status = section.status!;
      final query =
          _db.select(_db.watchStatuses).join([
              innerJoin(
                _db.cachedMedia,
                _db.cachedMedia.mediaId.equalsExp(_db.watchStatuses.mediaId) &
                    _db.cachedMedia.mediaType.equalsExp(
                      _db.watchStatuses.mediaType,
                    ),
              ),
            ])
            ..where(
              _db.watchStatuses.userId.equals(_userId) &
                  _db.watchStatuses.status.equalsValue(status),
            )
            ..orderBy([OrderingTerm.desc(_db.watchStatuses.updatedAt)]);

      final rows = await query.get();
      return rows.map((r) => _toSummary(r.readTable(_db.cachedMedia))).toList();
    });
  }

  @override
  Future<Result<void>> addToWatchlist(MediaSummary item, WatchStatus status) {
    return _guard(() async {
      _requireUserId();
      await _rememberInternal(item);
      await _db
          .into(_db.watchStatuses)
          .insertOnConflictUpdate(
            WatchStatusesCompanion.insert(
              userId: Value(_userId),
              mediaId: item.id,
              mediaType: item.type,
              status: status,
              updatedAt: Value(DateTime.now()),
            ),
          );
      _notify();
    });
  }

  @override
  Future<Result<void>> removeFromWatchlist(int id, MediaType type) =>
      setStatus(id, type, null);

  // ── FR-16 · Favourites ────────────────────────────────────────────────

  @override
  Future<Result<bool>> isFavourite(int id, MediaType type) {
    return _guard(() async {
      final row =
          await (_db.select(_db.favourites)..where(
                (t) =>
                    t.userId.equals(_userId) &
                    t.mediaId.equals(id) &
                    t.mediaType.equalsValue(type),
              ))
              .getSingleOrNull();
      return row != null;
    });
  }

  @override
  Future<Result<void>> setFavourite(
    MediaSummary item, {
    required bool favourite,
  }) {
    return _guard(() async {
      _requireUserId();
      if (favourite) {
        await _rememberInternal(item);
        await _db
            .into(_db.favourites)
            .insertOnConflictUpdate(
              FavouritesCompanion.insert(
                userId: Value(_userId),
                mediaId: item.id,
                mediaType: item.type,
              ),
            );
      } else {
        await (_db.delete(_db.favourites)..where(
              (t) =>
                  t.userId.equals(_userId) &
                  t.mediaId.equals(item.id) &
                  t.mediaType.equalsValue(item.type),
            ))
            .go();
      }
      _notify();
    });
  }

  @override
  Future<Result<List<MediaSummary>>> favourites() =>
      _guard(_summariesFromFavourites);

  Future<List<MediaSummary>> _summariesFromFavourites() async {
    final query =
        _db.select(_db.favourites).join([
            innerJoin(
              _db.cachedMedia,
              _db.cachedMedia.mediaId.equalsExp(_db.favourites.mediaId) &
                  _db.cachedMedia.mediaType.equalsExp(_db.favourites.mediaType),
            ),
          ])
          ..where(_db.favourites.userId.equals(_userId))
          ..orderBy([OrderingTerm.desc(_db.favourites.createdAt)]);

    final rows = await query.get();
    return rows.map((r) => _toSummary(r.readTable(_db.cachedMedia))).toList();
  }

  // ── FR-19 · Statistics ────────────────────────────────────────────────

  @override
  Future<Result<UserStatistics>> statistics() {
    return _guard(() async {
      final watched =
          await (_db.select(_db.watchStatuses)..where(
                (t) =>
                    t.userId.equals(_userId) &
                    t.status.equalsValue(WatchStatus.watched),
              ))
              .get();

      final movieIds = watched
          .where((w) => w.mediaType == MediaType.movie)
          .map((w) => w.mediaId)
          .toList();
      final seriesIds = watched
          .where((w) => w.mediaType == MediaType.series)
          .map((w) => w.mediaId)
          .toList();

      final episodes = await (_db.select(
        _db.episodeWatches,
      )..where((t) => t.userId.equals(_userId))).get();

      // 4 · مجموع زمان تقریبی تماشا — episode runtimes plus film runtimes.
      final episodeMinutes = episodes.fold(
        0,
        (sum, e) => sum + e.runtimeMinutes,
      );

      // The cached rows behind the watched titles, fetched once and reused for
      // both the runtime total and the genre breakdown.
      //
      // Matched on **both** halves of the primary key. Matching on `mediaId`
      // alone looked equivalent and is not: TMDB numbers films and series in
      // separate id spaces, so id 1 is a legitimate film *and* a legitimate
      // series, and a watched film would have picked up the genres of an
      // unrelated series that happened to share its number.
      final watchedMedia = <CachedMediaData>[
        if (movieIds.isNotEmpty)
          ...await (_db.select(_db.cachedMedia)..where(
                (t) =>
                    t.mediaId.isIn(movieIds) &
                    t.mediaType.equalsValue(MediaType.movie),
              ))
              .get(),
        if (seriesIds.isNotEmpty)
          ...await (_db.select(_db.cachedMedia)..where(
                (t) =>
                    t.mediaId.isIn(seriesIds) &
                    t.mediaType.equalsValue(MediaType.series),
              ))
              .get(),
      ];

      final filmMinutes = watchedMedia
          .where((m) => m.mediaType == MediaType.movie)
          .fold(0, (sum, f) => sum + f.runtimeMinutes);

      // 5 · ژانر موردعلاقه کاربر — most frequent genre across watched titles.
      final breakdown = <String, int>{};
      for (final media in watchedMedia) {
        for (final genre in media.genres.split(',')) {
          final name = genre.trim();
          if (name.isEmpty) continue;
          breakdown[name] = (breakdown[name] ?? 0) + 1;
        }
      }
      final favouriteGenre = breakdown.isEmpty
          ? null
          : (breakdown.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;

      return UserStatistics(
        moviesWatched: movieIds.length,
        seriesWatched: seriesIds.length,
        episodesWatched: episodes.length,
        totalMinutesWatched: episodeMinutes + filmMinutes,
        favouriteGenre: favouriteGenre,
        // 6 · میانگین امتیازهای ثبت شده — ratings arrive in Phase 5.
        genreBreakdown: breakdown,
      );
    });
  }

  // ── Cache maintenance ─────────────────────────────────────────────────

  @override
  Future<Result<void>> remember(
    MediaSummary item, {
    int? runtimeMinutes,
    List<String> genres = const [],
  }) {
    return _guard(() async {
      await _rememberInternal(
        item,
        runtimeMinutes: runtimeMinutes,
        genres: genres,
      );
    });
  }

  Future<void> _rememberInternal(
    MediaSummary item, {
    int? runtimeMinutes,
    List<String> genres = const [],
  }) async {
    final insert = CachedMediaCompanion.insert(
      mediaId: item.id,
      mediaType: item.type,
      title: item.title,
      posterPath: Value(item.posterPath),
      overview: Value(item.overview),
      releaseDate: Value(item.releaseDate),
      voteAverage: Value(item.voteAverage),
      runtimeMinutes: Value(runtimeMinutes ?? 0),
      genres: Value(genres.join(',')),
    );

    // On conflict, refresh only what this call actually knows.
    //
    // A blanket upsert would let `addToWatchlist` — which is handed a
    // [MediaSummary] and so has neither runtime nor genres — overwrite values
    // a detail screen had already cached, quietly emptying the FR-19
    // favourite-genre and watch-time statistics.
    await _db
        .into(_db.cachedMedia)
        .insert(
          insert,
          onConflict: DoUpdate(
            (_) => CachedMediaCompanion(
              title: Value(item.title),
              posterPath: Value(item.posterPath),
              overview: Value(item.overview),
              releaseDate: Value(item.releaseDate),
              voteAverage: Value(item.voteAverage),
              runtimeMinutes: runtimeMinutes == null
                  ? const Value.absent()
                  : Value(runtimeMinutes),
              genres: genres.isEmpty
                  ? const Value.absent()
                  : Value(genres.join(',')),
            ),
          ),
        );
  }

  @override
  Future<Result<void>> rememberSeriesProgress({
    required int seriesId,
    required int airedEpisodeCount,
    required bool hasFinishedAiring,
  }) {
    return _guard(() async {
      await _db
          .into(_db.seriesProgressMeta)
          .insertOnConflictUpdate(
            SeriesProgressMetaCompanion.insert(
              seriesId: Value(seriesId),
              airedEpisodeCount: Value(airedEpisodeCount),
              hasFinishedAiring: Value(hasFinishedAiring),
              updatedAt: Value(DateTime.now()),
            ),
          );
      _notify();
    });
  }

  MediaSummary _toSummary(CachedMediaData row) => MediaSummary(
    id: row.mediaId,
    type: row.mediaType,
    title: row.title,
    posterPath: row.posterPath,
    overview: row.overview,
    releaseDate: row.releaseDate,
    voteAverage: row.voteAverage,
  );

  void dispose() {
    _authSubscription?.cancel();
    _changes.close();
  }
}
