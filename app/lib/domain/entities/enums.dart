import '../../core/l10n/app_strings.dart';

/// Films vs. series. The brief treats them as distinct throughout (FR-06 vs.
/// FR-07, and separate carousels in FR-18), so the distinction is modelled
/// rather than inferred from which fields happen to be populated.
enum MediaType {
  movie,
  series;

  bool get isMovie => this == MediaType.movie;
  bool get isSeries => this == MediaType.series;
}

/// What the user declares about a title (FR-09 §5.9).
///
/// Deliberately narrow. "Paused" and "dropped" were dropped: they said the
/// same thing as one another and neither told the user anything the episode
/// marks of FR-10 do not already show. `favourite` is not here either — that
/// is the heart of FR-16, a flag a title carries *alongside* a status rather
/// than instead of one, and modelling it as a status meant marking something
/// favourite silently erased whether you had watched it.
enum WatchStatus {
  planToWatch(AppStrings.statusPlanToWatch),
  watching(AppStrings.statusWatching),
  watched(AppStrings.statusWatched);

  const WatchStatus(this.label);

  /// Persian label shown in the UI.
  final String label;

  /// The statuses offered for [type].
  ///
  /// A film is either seen or not, so it has no "in progress"; a series does,
  /// because it is watched an episode at a time.
  static List<WatchStatus> availableFor(MediaType type) => switch (type) {
    MediaType.movie => const [WatchStatus.watched, WatchStatus.planToWatch],
    MediaType.series => const [
      WatchStatus.watched,
      WatchStatus.watching,
      WatchStatus.planToWatch,
    ],
  };
}

/// Broadcast status of a series (FR-07 field 7).
///
/// Needed by FR-11 to tell green (all watched, more episodes coming) from
/// purple (all watched, nothing more will be released).
enum SeriesStatus {
  returning('در حال پخش'),
  ended('پایان‌یافته'),
  canceled('لغو شده'),
  inProduction('در حال تولید'),
  planned('برنامه‌ریزی شده'),
  unknown('نامشخص');

  const SeriesStatus(this.label);

  final String label;

  /// True when no further episodes will be released — the distinction that
  /// drives the purple vs. green decision in FR-11.
  bool get isFinished =>
      this == SeriesStatus.ended || this == SeriesStatus.canceled;

  /// Maps the TMDB `status` string onto this enum.
  static SeriesStatus fromApi(String? raw) => switch (raw?.toLowerCase()) {
    'returning series' => SeriesStatus.returning,
    'ended' => SeriesStatus.ended,
    'canceled' || 'cancelled' => SeriesStatus.canceled,
    'in production' => SeriesStatus.inProduction,
    'planned' || 'pilot' => SeriesStatus.planned,
    _ => SeriesStatus.unknown,
  };
}
