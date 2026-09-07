import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/social/social_activity.dart';
import '../../../domain/entities/watch_progress.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../auth/presentation/auth_providers.dart';

/// Identifies one title. Films and series share an id space upstream only by
/// accident, so both halves are always carried together.
typedef MediaKey = ({int id, MediaType type});

/// Ticks whenever tracking data changes.
///
/// Every read provider below watches this, so marking an episode refreshes the
/// progress bar, the watchlist, and the statistics at once — without any
/// screen polling or manually invalidating its neighbours.
final trackingRevisionProvider = StreamProvider<void>((ref) {
  return ref.watch(trackingRepositoryProvider).changes;
});

// Account switches arrive on `trackingRevisionProvider` too: the repository
// subscribes to the auth stream and emits a change when the signed-in user
// changes. Watching a StreamProvider of the auth state here instead looked
// tidier but deadlocked — `currentUser` has no current value, so the provider
// sat in `AsyncLoading` and reads of it never completed.

/// FR-09 — the current status of a title, or `null` if untracked.
final watchStatusProvider = FutureProvider.family<WatchStatus?, MediaKey>((
  ref,
  key,
) async {
  ref.watch(trackingRevisionProvider);
  final result = await ref
      .watch(trackingRepositoryProvider)
      .statusOf(key.id, key.type);
  return result.valueOrNull;
});

/// FR-16 — whether a title is a favourite.
final isFavouriteProvider = FutureProvider.family<bool, MediaKey>((
  ref,
  key,
) async {
  ref.watch(trackingRevisionProvider);
  final result = await ref
      .watch(trackingRepositoryProvider)
      .isFavourite(key.id, key.type);
  return result.valueOrNull ?? false;
});

/// FR-10 — which episodes of a series the user has marked watched.
final watchedEpisodesProvider = FutureProvider.family<Set<int>, int>((
  ref,
  seriesId,
) async {
  ref.watch(trackingRevisionProvider);
  final result = await ref
      .watch(trackingRepositoryProvider)
      .watchedEpisodeIds(seriesId);
  return result.valueOrNull ?? const {};
});

/// FR-11 — progress for one series.
final seriesProgressProvider = FutureProvider.family<WatchProgress, int>((
  ref,
  seriesId,
) async {
  ref.watch(trackingRevisionProvider);
  final result = await ref
      .watch(trackingRepositoryProvider)
      .progressOf(seriesId);
  return result.valueOrNull ?? const WatchProgress.empty();
});

/// FR-11 — progress for a whole list of series in one query, so a scrolling
/// grid of posters does not cost a query per card.
final progressForAllProvider =
    FutureProvider.family<Map<int, WatchProgress>, List<int>>((ref, ids) async {
      ref.watch(trackingRevisionProvider);
      final result = await ref
          .watch(trackingRepositoryProvider)
          .progressForAll(ids);
      return result.valueOrNull ?? const {};
    });

/// FR-12 — one section of the watchlist.
final watchlistProvider =
    FutureProvider.family<List<MediaSummary>, WatchlistSection>((
      ref,
      section,
    ) async {
      ref.watch(trackingRevisionProvider);
      final result = await ref
          .watch(trackingRepositoryProvider)
          .watchlist(section);
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => throw failure,
      };
    });

/// FR-01 — the three counters shown on the profile.
///
/// Derived live rather than read from the cached [AppUser]: that snapshot is
/// built at sign-in, so anything tracked afterwards did not appear until the
/// next login.
typedef ProfileCounters = ({
  int moviesWatched,
  int seriesFollowed,
  int favourites,
});

final profileCountersProvider = FutureProvider<ProfileCounters>((ref) async {
  ref.watch(trackingRevisionProvider);

  final repository = ref.watch(trackingRepositoryProvider);
  final watched = await repository.watchlist(WatchlistSection.watched);
  final watching = await repository.watchlist(WatchlistSection.watching);
  final later = await repository.watchlist(WatchlistSection.watchLater);
  final favourites = await repository.favourites();

  final films = (watched.valueOrNull ?? const [])
      .where((i) => i.type.isMovie)
      .length;

  // "دنبال شده" covers anything actively tracked, not only finished series.
  final followed = <int>{
    for (final list in <Result<List<MediaSummary>>>[watched, watching, later])
      for (final item in list.valueOrNull ?? const <MediaSummary>[])
        if (item.type.isSeries) item.id,
  }.length;

  return (
    moviesWatched: films,
    seriesFollowed: followed,
    favourites: (favourites.valueOrNull ?? const []).length,
  );
});

/// FR-19 — the six activity statistics.
///
/// A failure is rethrown rather than folded into an empty [UserStatistics].
/// Swallowing it made a broken read indistinguishable from a user who has
/// tracked nothing: the screen said «هنوز فعالیتی ثبت نشده است» over an
/// account whose profile was showing counters at the same moment. NFR-09 wants
/// the error said out loud.
final statisticsProvider = FutureProvider<UserStatistics>((ref) async {
  ref.watch(trackingRevisionProvider);
  final result = await ref.watch(trackingRepositoryProvider).statistics();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Write-side helper.
///
/// Bundling the mutations here keeps widgets free of repository plumbing, and
/// gives one place to enforce the rule that a title is always cached before it
/// is referenced — otherwise the watchlist would show blank cards offline.
class TrackingActions {
  const TrackingActions(this._repository, [this._ref]);

  final TrackingRepository _repository;
  final Ref? _ref;

  /// FR-09. Setting a status also adds the title to the watchlist, which is
  /// what FR-12's sections are populated from.
  Future<void> setStatus(MediaSummary item, WatchStatus? status) async {
    if (status == null) {
      await _repository.removeFromWatchlist(item.id, item.type);
    } else {
      await _repository.addToWatchlist(item, status);
    }

    // Calling a series watched means every episode is watched, so record the
    // episode marks too — otherwise FR-11's bar would still read part-way and
    // the season screen would still show unticked episodes.
    if (status == WatchStatus.watched && item.type.isSeries) {
      await _markEveryEpisodeWatched(item.id);
    }

    if (status == WatchStatus.watched && _ref != null) {
      _syncWatchedToCloud(item);
    }
  }

  /// Ticks every aired episode of [seriesId], season by season.
  ///
  /// Only aired episodes are marked: the progress denominator is the aired
  /// count (see `SeriesProgressMeta`), so marking future episodes as well
  /// would not move the bar and would claim the user had seen something that
  /// does not exist yet.
  Future<void> _markEveryEpisodeWatched(int seriesId) async {
    final ref = _ref;
    if (ref == null) return;

    final catalog = ref.read(catalogRepositoryProvider);

    final seriesRes = await catalog.seriesDetails(seriesId);
    final series = seriesRes.valueOrNull;
    if (series == null) return;

    for (final summary in series.seasons) {
      // Specials sit outside the numbered run and are excluded from the aired
      // count, so ticking them could push the bar past 100%.
      if (summary.isSpecials) continue;

      final seasonRes = await catalog.season(seriesId, summary.seasonNumber);
      final episodes = seasonRes.valueOrNull?.episodes ?? const [];
      final aired = episodes.where((e) => e.hasAired).toList();
      if (aired.isEmpty) continue;

      await _repository.setSeasonWatched(
        seriesId,
        summary.seasonNumber,
        [for (final e in aired) e.id],
        watched: true,
        runtimes: {for (final e in aired) e.id: e.runtime ?? 0},
        episodeNumbers: {for (final e in aired) e.id: e.episodeNumber},
      );
    }
  }

  void _syncWatchedToCloud(MediaSummary item) {
    try {
      final user = _ref?.read(currentUserProvider).valueOrNull ??
          _ref?.read(authRepositoryProvider).currentUserOrNull;
      if (user == null) return;

      final socialRepo = _ref?.read(socialRepositoryProvider);
      if (socialRepo != null) {
        socialRepo.logActivity(
          SocialActivity(
            activityId: SocialActivity.buildId(
              prefix: 'watch',
              userId: user.id,
              mediaType: item.type,
              mediaId: item.id,
            ),
            userId: user.id,
            actionType: SocialActionType.watched,
            movieId: item.id,
            mediaType: item.type,
            timestamp: DateTime.now(),
            movieTitle: item.title,
            moviePoster: item.posterPath,
            username: user.displayName,
            userAvatar: user.avatarPath,
          ),
        );
      }

      unawaited(syncProfileStats());
      _ref?.read(socialActivityRevisionProvider.notifier).state++;
    } catch (_) {}
  }

  /// Publishes the local watch total onto the public profile.
  ///
  /// Writes the total outright rather than incrementing a counter: a
  /// read-modify-write drifts the moment a write is lost or a title is
  /// un-watched, and the number on a profile is supposed to match the list
  /// behind it. Films and series are counted together (FR-19 keeps them
  /// apart; the profile headline does not).
  Future<void> syncProfileStats() async {
    final ref = _ref;
    if (ref == null) return;

    try {
      final user = ref.read(currentUserProvider).valueOrNull ??
          ref.read(authRepositoryProvider).currentUserOrNull;
      final supabase = ref.read(supabaseClientProvider);
      if (user == null || supabase == null) return;

      final stats = (await _repository.statistics()).valueOrNull;
      if (stats == null) return;

      // Deliberately does not touch `favorite_genre`: that is the user's own
      // answer now, set on the profile screen, and inferring one from watch
      // history would quietly overwrite what they chose.
      await supabase.from('public_profiles').update({
        'total_watched': stats.moviesWatched + stats.seriesWatched,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', user.id);
    } catch (_) {
      // Stats on a profile are not worth failing a watch over.
    }
  }

  /// FR-16.
  Future<void> toggleFavourite(
    MediaSummary item, {
    required bool favourite,
  }) async {
    await _repository.setFavourite(item, favourite: favourite);
    await _syncFavouriteToCloud(item, favourite: favourite);
  }

  /// Mirrors the heart onto the profile.
  ///
  /// The favourites table lives on this device, so without a copy in the
  /// shared activity log nobody else could ever see what a user has
  /// favourited — which is what a profile is for.
  Future<void> _syncFavouriteToCloud(
    MediaSummary item, {
    required bool favourite,
  }) async {
    final ref = _ref;
    if (ref == null) return;

    try {
      final user = ref.read(currentUserProvider).valueOrNull ??
          ref.read(authRepositoryProvider).currentUserOrNull;
      if (user == null) return;

      final socialRepo = ref.read(socialRepositoryProvider);
      final activityId = SocialActivity.buildId(
        prefix: 'fav',
        userId: user.id,
        mediaType: item.type,
        mediaId: item.id,
      );

      if (favourite) {
        await socialRepo.logActivity(
          SocialActivity(
            activityId: activityId,
            userId: user.id,
            actionType: SocialActionType.favourited,
            movieId: item.id,
            mediaType: item.type,
            timestamp: DateTime.now(),
            movieTitle: item.title,
            moviePoster: item.posterPath,
            username: user.displayName,
            userAvatar: user.avatarPath,
          ),
        );
      } else {
        await socialRepo.deleteActivity(activityId);
      }

      // The favourites section and the diary read the activity log, so they
      // have to be told it moved.
      ref.read(socialActivityRevisionProvider.notifier).state++;
    } catch (_) {
      // A profile that lags behind is not worth failing the heart over.
    }
  }

  /// FR-10 — a single episode.
  Future<void> setEpisodeWatched({
    required int seriesId,
    required int episodeId,
    required int seasonNumber,
    required int episodeNumber,
    required int runtimeMinutes,
    required bool watched,
  }) => _repository.setEpisodeWatched(
    seriesId,
    episodeId,
    watched: watched,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
    runtimeMinutes: runtimeMinutes,
  );

  /// FR-10 — the "mark whole season" bulk action.
  Future<void> setSeasonWatched({
    required int seriesId,
    required int seasonNumber,
    required List<int> episodeIds,
    required Map<int, int> runtimes,
    required Map<int, int> episodeNumbers,
    required bool watched,
  }) => _repository.setSeasonWatched(
    seriesId,
    seasonNumber,
    episodeIds,
    watched: watched,
    runtimes: runtimes,
    episodeNumbers: episodeNumbers,
  );

  /// Records the FR-11 denominator when a series detail is opened.
  ///
  /// Only aired episodes count. Including unaired ones would leave a viewer
  /// who is fully caught up permanently short of 100%, which is not what the
  /// brief's worked example describes.
  Future<void> rememberSeries(Series series) async {
    await _repository.remember(
      MediaSummary(
        id: series.id,
        type: MediaType.series,
        title: series.name,
        posterPath: series.posterPath,
        overview: series.overview,
        releaseDate: series.firstAirDate,
        voteAverage: series.voteAverage,
      ),
      runtimeMinutes: series.averageEpisodeRuntime,
      genres: series.genres.map((g) => g.name).toList(),
    );

    await _repository.rememberSeriesProgress(
      seriesId: series.id,
      airedEpisodeCount: series.airedEpisodeCount,
      hasFinishedAiring: series.hasFinishedAiring,
    );
  }

  /// Caches a film so the watchlist renders offline and FR-19's watch-time
  /// statistic can include it.
  Future<void> rememberMovie(
    MediaSummary item, {
    required int runtimeMinutes,
    required List<String> genres,
  }) => _repository.remember(
    item,
    runtimeMinutes: runtimeMinutes,
    genres: genres,
  );
}

final trackingActionsProvider = Provider<TrackingActions>((ref) {
  return TrackingActions(ref.watch(trackingRepositoryProvider), ref);
});
