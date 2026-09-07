import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/entities/watch_progress.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/tracking_repository.dart';

/// Everything the user records about what they watch, held in Supabase.
///
/// Moved off the device so an account carries its history: signing in on a
/// second phone brings the watchlist, the episode marks and the favourites
/// with it, which a local SQLite file never could.
///
/// Aggregates — the FR-19 statistics — are computed here rather than in SQL.
/// PostgREST exposes no `group by`, and one person's watch history is small
/// enough that fetching it and folding it in Dart costs less than the round
/// trips a view would need.
class SupabaseTrackingRepository implements TrackingRepository {
  SupabaseTrackingRepository(this._client, this._auth) {
    // An account switch changes every answer this repository gives, so it
    // counts as a change like any write.
    _authSubscription = _auth.currentUser.listen((_) => _notify());
  }

  final SupabaseClient _client;
  final AuthRepository _auth;

  final _changes = StreamController<void>.broadcast();
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _changes.close();
  }

  String get _userId {
    final id = _auth.currentUserOrNull?.id;
    if (id == null) throw const UnauthorizedFailure();
    return id;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e, stack) {
      debugPrint('[SupabaseTrackingRepository] $e\n$stack');
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  // ── FR-09 · Watch status ────────────────────────────────────────────────

  @override
  Future<Result<WatchStatus?>> statusOf(int id, MediaType type) {
    return _guard(() async {
      final row = await _client
          .from('watch_statuses')
          .select('status')
          .match({
            'user_id': _userId,
            'media_id': id,
            'media_type': type.name,
          })
          .maybeSingle();
      if (row == null) return null;
      return WatchStatus.values.asNameMap()[row['status'] as String?];
    });
  }

  @override
  Future<Result<void>> setStatus(int id, MediaType type, WatchStatus? status) {
    if (status == null) return removeFromWatchlist(id, type);
    return _guard(() async {
      await _client.from('watch_statuses').upsert({
        'user_id': _userId,
        'media_id': id,
        'media_type': type.name,
        'status': status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      _notify();
    });
  }

  // ── FR-10 · Episode marks ───────────────────────────────────────────────

  @override
  Future<Result<Set<int>>> watchedEpisodeIds(int seriesId) {
    return _guard(() async {
      final rows = await _client
          .from('episode_watches')
          .select('episode_id')
          .match({'user_id': _userId, 'series_id': seriesId});
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((r) => (r['episode_id'] as num).toInt())
          .toSet();
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
      if (watched) {
        await _client.from('episode_watches').upsert({
          'user_id': _userId,
          'episode_id': episodeId,
          'series_id': seriesId,
          'season_number': seasonNumber,
          'episode_number': episodeNumber,
          'runtime_minutes': runtimeMinutes,
          'watched_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await _client
            .from('episode_watches')
            .delete()
            .match({'user_id': _userId, 'episode_id': episodeId});
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
      if (episodeIds.isEmpty) return;

      if (watched) {
        // One request for the whole season: marking 24 episodes one at a time
        // would be 24 round trips and could leave the bar half-filled if the
        // connection dropped part-way.
        await _client.from('episode_watches').upsert([
          for (final id in episodeIds)
            {
              'user_id': _userId,
              'episode_id': id,
              'series_id': seriesId,
              'season_number': seasonNumber,
              'episode_number': episodeNumbers[id] ?? 0,
              'runtime_minutes': runtimes[id] ?? 0,
              'watched_at': DateTime.now().toUtc().toIso8601String(),
            },
        ]);
      } else {
        await _client
            .from('episode_watches')
            .delete()
            .eq('user_id', _userId)
            .inFilter('episode_id', episodeIds);
      }
      _notify();
    });
  }

  // ── FR-11 · Progress ────────────────────────────────────────────────────

  @override
  Future<Result<WatchProgress>> progressOf(int seriesId) async {
    final all = await progressForAll([seriesId]);
    return all.map((byId) => byId[seriesId] ?? const WatchProgress.empty());
  }

  @override
  Future<Result<Map<int, WatchProgress>>> progressForAll(List<int> seriesIds) {
    return _guard(() async {
      if (seriesIds.isEmpty) return <int, WatchProgress>{};

      // Three set-based reads rather than three per series.
      final watchRows = await _client
          .from('episode_watches')
          .select('series_id')
          .eq('user_id', _userId)
          .inFilter('series_id', seriesIds);

      final metaRows = await _client
          .from('series_progress_meta')
          .select()
          .inFilter('series_id', seriesIds);

      final statusRows = await _client
          .from('watch_statuses')
          .select('media_id,status')
          .eq('user_id', _userId)
          .eq('media_type', MediaType.series.name)
          .inFilter('media_id', seriesIds);

      final watched = <int, int>{};
      for (final row in (watchRows as List).cast<Map<String, dynamic>>()) {
        final id = (row['series_id'] as num).toInt();
        watched[id] = (watched[id] ?? 0) + 1;
      }

      final meta = {
        for (final row in (metaRows as List).cast<Map<String, dynamic>>())
          (row['series_id'] as num).toInt(): row,
      };

      final statuses = {
        for (final row in (statusRows as List).cast<Map<String, dynamic>>())
          (row['media_id'] as num).toInt():
              WatchStatus.values.asNameMap()[row['status'] as String?],
      };

      return {
        for (final id in seriesIds)
          id: WatchProgress(
            watchedEpisodes: watched[id] ?? 0,
            totalEpisodes:
                (meta[id]?['aired_episode_count'] as num?)?.toInt() ?? 0,
            hasFinishedAiring:
                meta[id]?['has_finished_airing'] as bool? ?? false,
            userStatus: statuses[id],
          ),
      };
    });
  }

  @override
  Future<Result<void>> rememberSeriesProgress({
    required int seriesId,
    required int airedEpisodeCount,
    required bool hasFinishedAiring,
  }) {
    return _guard(() async {
      await _client.from('series_progress_meta').upsert({
        'series_id': seriesId,
        'aired_episode_count': airedEpisodeCount,
        'has_finished_airing': hasFinishedAiring,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      _notify();
    });
  }

  // ── FR-12 · Watchlist ───────────────────────────────────────────────────

  @override
  Future<Result<List<MediaSummary>>> watchlist(WatchlistSection section) {
    return _guard(() async {
      if (section == WatchlistSection.favourites) {
        final rows = await _client
            .from('favourites')
            .select('media_id,media_type')
            .eq('user_id', _userId)
            .order('created_at', ascending: false);
        return _summariesFor((rows as List).cast<Map<String, dynamic>>());
      }

      final status = section.status;
      if (status == null) return <MediaSummary>[];

      final rows = await _client
          .from('watch_statuses')
          .select('media_id,media_type')
          .match({'user_id': _userId, 'status': status.name})
          .order('updated_at', ascending: false);
      return _summariesFor((rows as List).cast<Map<String, dynamic>>());
    });
  }

  @override
  Future<Result<void>> addToWatchlist(MediaSummary item, WatchStatus status) {
    return _guard(() async {
      await _rememberInternal(item);
      await _client.from('watch_statuses').upsert({
        'user_id': _userId,
        'media_id': item.id,
        'media_type': item.type.name,
        'status': status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      _notify();
    });
  }

  @override
  Future<Result<void>> removeFromWatchlist(int id, MediaType type) {
    return _guard(() async {
      await _client.from('watch_statuses').delete().match({
        'user_id': _userId,
        'media_id': id,
        'media_type': type.name,
      });
      _notify();
    });
  }

  // ── FR-16 · Favourites ──────────────────────────────────────────────────

  @override
  Future<Result<bool>> isFavourite(int id, MediaType type) {
    return _guard(() async {
      final row = await _client
          .from('favourites')
          .select('media_id')
          .match({
            'user_id': _userId,
            'media_id': id,
            'media_type': type.name,
          })
          .maybeSingle();
      return row != null;
    });
  }

  @override
  Future<Result<void>> setFavourite(
    MediaSummary item, {
    required bool favourite,
  }) {
    return _guard(() async {
      if (favourite) {
        await _rememberInternal(item);
        await _client.from('favourites').upsert({
          'user_id': _userId,
          'media_id': item.id,
          'media_type': item.type.name,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await _client.from('favourites').delete().match({
          'user_id': _userId,
          'media_id': item.id,
          'media_type': item.type.name,
        });
      }
      _notify();
    });
  }

  @override
  Future<Result<List<MediaSummary>>> favourites() =>
      watchlist(WatchlistSection.favourites);

  // ── FR-19 · Statistics ──────────────────────────────────────────────────

  @override
  Future<Result<UserStatistics>> statistics() {
    return _guard(() async {
      final watchedRows = await _client
          .from('watch_statuses')
          .select('media_id,media_type')
          .match({'user_id': _userId, 'status': WatchStatus.watched.name});

      final episodeRows = await _client
          .from('episode_watches')
          .select('runtime_minutes')
          .eq('user_id', _userId);

      final ratingRows = await _client
          .from('ratings')
          .select('stars')
          .eq('user_id', _userId);

      final watched = (watchedRows as List).cast<Map<String, dynamic>>();
      final films = watched
          .where((r) => r['media_type'] == MediaType.movie.name)
          .toList();
      final series = watched
          .where((r) => r['media_type'] == MediaType.series.name)
          .toList();

      final episodes = (episodeRows as List).cast<Map<String, dynamic>>();
      final episodeMinutes = episodes.fold<int>(
        0,
        (sum, r) => sum + ((r['runtime_minutes'] as num?)?.toInt() ?? 0),
      );

      // Films contribute their own runtime; series time is counted per
      // episode, so the cached film rows are the only ones needed here.
      final cached = await _cachedFor(films);
      final filmMinutes = cached.values.fold<int>(
        0,
        (sum, r) => sum + ((r['runtime_minutes'] as num?)?.toInt() ?? 0),
      );

      final genreCounts = <String, int>{};
      for (final row in (await _cachedFor(watched)).values) {
        final raw = (row['genres'] as String? ?? '').trim();
        if (raw.isEmpty) continue;
        for (final genre in raw.split(',')) {
          final name = genre.trim();
          if (name.isEmpty) continue;
          genreCounts[name] = (genreCounts[name] ?? 0) + 1;
        }
      }

      String? favouriteGenre;
      var best = 0;
      for (final entry in genreCounts.entries) {
        if (entry.value > best) {
          best = entry.value;
          favouriteGenre = entry.key;
        }
      }

      final stars = (ratingRows as List)
          .cast<Map<String, dynamic>>()
          .map((r) => (r['stars'] as num).toInt())
          .toList();

      return UserStatistics(
        moviesWatched: films.length,
        seriesWatched: series.length,
        episodesWatched: episodes.length,
        totalMinutesWatched: filmMinutes + episodeMinutes,
        favouriteGenre: favouriteGenre,
        averageRating: stars.isEmpty
            ? null
            : stars.reduce((a, b) => a + b) / stars.length,
        genreBreakdown: genreCounts,
      );
    });
  }

  // ── Catalogue cache ─────────────────────────────────────────────────────

  @override
  Future<Result<void>> remember(
    MediaSummary item, {
    int? runtimeMinutes,
    List<String> genres = const [],
  }) {
    return _guard(() async {
      await _rememberInternal(
        item,
        runtimeMinutes: runtimeMinutes ?? 0,
        genres: genres,
      );
    });
  }

  /// Caches enough of a title to draw its card without another network call.
  ///
  /// Shared across accounts: a film's title and poster do not differ per
  /// user, so storing a copy per account would multiply the same rows by the
  /// number of people using the app.
  Future<void> _rememberInternal(
    MediaSummary item, {
    int runtimeMinutes = 0,
    List<String> genres = const [],
  }) async {
    await _client.from('cached_media').upsert({
      'media_id': item.id,
      'media_type': item.type.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'overview': item.overview,
      'release_date': item.releaseDate,
      'vote_average': item.voteAverage,
      if (runtimeMinutes > 0) 'runtime_minutes': runtimeMinutes,
      if (genres.isNotEmpty) 'genres': genres.join(','),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Cached rows for a set of (media_id, media_type) references, keyed the
  /// same way so a film and a series sharing an id stay apart.
  Future<Map<String, Map<String, dynamic>>> _cachedFor(
    List<Map<String, dynamic>> references,
  ) async {
    if (references.isEmpty) return {};

    final ids = references
        .map((r) => (r['media_id'] as num).toInt())
        .toSet()
        .toList();

    final rows = await _client
        .from('cached_media')
        .select()
        .inFilter('media_id', ids);

    final wanted = references
        .map((r) => '${r['media_id']}:${r['media_type']}')
        .toSet();

    return {
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        if (wanted.contains('${row['media_id']}:${row['media_type']}'))
          '${row['media_id']}:${row['media_type']}': row,
    };
  }

  /// Turns watchlist references into cards, keeping the order they came in.
  Future<List<MediaSummary>> _summariesFor(
    List<Map<String, dynamic>> references,
  ) async {
    final cached = await _cachedFor(references);

    return [
      for (final reference in references)
        if (cached['${reference['media_id']}:${reference['media_type']}']
            case final row?)
          MediaSummary(
            id: (row['media_id'] as num).toInt(),
            type: row['media_type'] == MediaType.series.name
                ? MediaType.series
                : MediaType.movie,
            title: row['title'] as String? ?? '',
            posterPath: row['poster_path'] as String?,
            overview: row['overview'] as String?,
            releaseDate: row['release_date'] as String?,
            voteAverage: (row['vote_average'] as num?)?.toDouble(),
          ),
    ];
  }
}
