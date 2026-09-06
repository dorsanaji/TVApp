import '../../core/error/result.dart';
import '../entities/enums.dart';
import '../entities/media_summary.dart';
import '../entities/watch_progress.dart';

/// Everything the user records about what they watch.
///
/// Covers FR-09 (watch status), FR-10 (episode marks), FR-11 (progress),
/// FR-12 (watchlist), FR-16 (favourites), and FR-19 (statistics).
///
/// In the normal model this is backed by the local database (NM-07); in the
/// advanced model it is backed by the project backend. Callers cannot tell,
/// which is the point.
///
/// Writes must be idempotent — NFR-22 requires that recording a rating,
/// review, or watch status is never unintentionally repeated.
abstract interface class TrackingRepository {
  // ── FR-09 · Watch status ──────────────────────────────────────────────

  Future<Result<WatchStatus?>> statusOf(int id, MediaType type);

  /// Passing `null` clears the status.
  Future<Result<void>> setStatus(int id, MediaType type, WatchStatus? status);

  // ── FR-10 · Episode marks ─────────────────────────────────────────────

  Future<Result<Set<int>>> watchedEpisodeIds(int seriesId);

  /// Season and episode numbers and the runtime are passed in at mark time so
  /// the FR-19 total-watch-time statistic can be computed later without
  /// re-fetching every season the user has ever watched (NFR-42).
  Future<Result<void>> setEpisodeWatched(
    int seriesId,
    int episodeId, {
    required bool watched,
    int seasonNumber,
    int episodeNumber,
    int runtimeMinutes,
  });

  /// Bulk "mark whole season" action. Applied in one transaction, so an
  /// interruption cannot leave the progress bar reporting a partial season.
  Future<Result<void>> setSeasonWatched(
    int seriesId,
    int seasonNumber,
    List<int> episodeIds, {
    required bool watched,
    Map<int, int> runtimes,
    Map<int, int> episodeNumbers,
  });

  // ── FR-11 · Progress ──────────────────────────────────────────────────

  /// Progress for one series, ready for the progress bar.
  Future<Result<WatchProgress>> progressOf(int seriesId);

  /// Progress for many series at once — the home and watchlist screens draw a
  /// bar on every poster, and issuing one query per card would violate
  /// NFR-01 and NFR-05.
  Future<Result<Map<int, WatchProgress>>> progressForAll(List<int> seriesIds);

  // ── FR-12 · Watchlist ─────────────────────────────────────────────────

  /// Items in one section of the watchlist.
  Future<Result<List<MediaSummary>>> watchlist(WatchlistSection section);

  Future<Result<void>> addToWatchlist(MediaSummary item, WatchStatus status);

  Future<Result<void>> removeFromWatchlist(int id, MediaType type);

  // ── FR-16 · Favourites ────────────────────────────────────────────────

  Future<Result<bool>> isFavourite(int id, MediaType type);

  Future<Result<void>> setFavourite(
    MediaSummary item, {
    required bool favourite,
  });

  Future<Result<List<MediaSummary>>> favourites();

  // ── FR-19 · Statistics ────────────────────────────────────────────────

  Future<Result<UserStatistics>> statistics();

  // ── Cache maintenance ─────────────────────────────────────────────────

  /// Stores enough of a title to render its card offline (NFR-20) and to feed
  /// the FR-19 statistics without re-fetching.
  Future<Result<void>> remember(
    MediaSummary item, {
    int? runtimeMinutes,
    List<String> genres,
  });

  /// Records the denominator and broadcast state the FR-11 progress bar needs.
  ///
  /// Kept per series so a bar can be drawn on every poster in a scrolling list
  /// without a detail request per card, which NFR-01 and NFR-05 both forbid.
  Future<Result<void>> rememberSeriesProgress({
    required int seriesId,
    required int airedEpisodeCount,
    required bool hasFinishedAiring,
  });

  /// Emits whenever tracking data changes, so screens showing progress or list
  /// membership refresh without polling.
  Stream<void> get changes;
}

/// The four sections named in FR-12 §5.12.
enum WatchlistSection {
  watching,
  watched,
  watchLater,
  favourites;

  /// The FR-09 status that populates this section, where one applies.
  /// Favourites are driven by the separate favourites flag of FR-16.
  WatchStatus? get status => switch (this) {
    WatchlistSection.watching => WatchStatus.watching,
    WatchlistSection.watched => WatchStatus.watched,
    WatchlistSection.watchLater => WatchStatus.planToWatch,
    WatchlistSection.favourites => null,
  };
}

/// The six statistics required by FR-19 §5.19.
class UserStatistics {
  const UserStatistics({
    this.moviesWatched = 0,
    this.seriesWatched = 0,
    this.episodesWatched = 0,
    this.totalMinutesWatched = 0,
    this.favouriteGenre,
    this.averageRating,
    this.genreBreakdown = const {},
  });

  /// 1 — تعداد فیلم‌های مشاهده شده
  final int moviesWatched;

  /// 2 — تعداد سریال‌های مشاهده شده
  final int seriesWatched;

  /// 3 — تعداد قسمت‌های مشاهده شده
  final int episodesWatched;

  /// 4 — مجموع زمان تقریبی تماشا
  final int totalMinutesWatched;

  /// 5 — ژانر موردعلاقه کاربر, by frequency across watched titles.
  final String? favouriteGenre;

  /// 6 — میانگین امتیازهای ثبت شده, on the 1–5 scale of FR-13.
  final double? averageRating;

  /// Backing data for the genre chart.
  final Map<String, int> genreBreakdown;
}
