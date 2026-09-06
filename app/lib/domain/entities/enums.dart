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

/// The six statuses named in FR-09 §5.9.
///
/// Note that `favourite` is listed there as a status *and* separately in
/// FR-16 as its own list. It is kept in both places deliberately: the brief
/// asks for both, and a user can mark something favourite while also having
/// it "in progress".
enum WatchStatus {
  planToWatch(AppStrings.statusPlanToWatch),
  watching(AppStrings.statusWatching),
  watched(AppStrings.statusWatched),
  paused(AppStrings.statusPaused),
  dropped(AppStrings.statusDropped),
  favourite(AppStrings.statusFavourite);

  const WatchStatus(this.label);

  /// Persian label shown in the UI.
  final String label;

  /// FR-11 treats "paused" and "dropped" alike: both mean the user stopped
  /// watching without finishing, which is the red progress state.
  bool get isStopped =>
      this == WatchStatus.paused || this == WatchStatus.dropped;
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
