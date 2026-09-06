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

    if (status == WatchStatus.watched && _ref != null) {
      _syncWatchedToCloud(item);
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
            activityId: 'watch_${user.id}_${item.id}',
            userId: user.id,
            actionType: SocialActionType.watched,
            movieId: item.id,
            timestamp: DateTime.now(),
            movieTitle: item.title,
            moviePoster: item.posterPath,
            username: user.displayName,
            userAvatar: user.avatarPath,
          ),
        );
      }

      final supabase = _ref?.read(supabaseClientProvider);
      if (supabase != null) {
        supabase
            .from('public_profiles')
            .select('total_watched')
            .eq('user_id', user.id)
            .maybeSingle()
            .then((row) {
          final current = (row?['total_watched'] as num?)?.toInt() ?? 0;
          supabase.from('public_profiles').update({
            'total_watched': current + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('user_id', user.id);
        }).catchError((_) {});
      }
    } catch (_) {}
  }

  /// FR-16.
  Future<void> toggleFavourite(MediaSummary item, {required bool favourite}) =>
      _repository.setFavourite(item, favourite: favourite);

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
      airedEpisodeCount: series.numberOfEpisodes,
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
