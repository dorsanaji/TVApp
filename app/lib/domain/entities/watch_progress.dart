import 'enums.dart';

/// The five progress states prescribed by FR-11 §5.11.
///
/// The brief names each colour and its meaning explicitly, so they are modelled
/// as a closed set rather than left to the widget. The colour values themselves
/// live in `AppColors`; this enum is the *meaning*, which is what gets tested.
enum ProgressState {
  /// بی‌رنگ یا مشکی — no episodes watched.
  none,

  /// سبز — every aired episode watched, but more will be released.
  ongoingComplete,

  /// بنفش — every episode watched and nothing further will be released.
  finishedComplete,

  /// زرد — unwatched episodes remain.
  partial,
}

/// Watch progress for one series (FR-11).
///
/// Deliberately a domain object rather than widget state: the rule that picks
/// the state depends on three inputs — how much is watched, whether the series
/// has finished airing, and what the user declared in FR-09 — and getting that
/// combination right is the whole of the requirement.
class WatchProgress {
  const WatchProgress({
    required this.watchedEpisodes,
    required this.totalEpisodes,
    required this.hasFinishedAiring,
    this.userStatus,
  });

  const WatchProgress.empty()
    : watchedEpisodes = 0,
      totalEpisodes = 0,
      hasFinishedAiring = false,
      userStatus = null;

  /// Episodes the user has marked watched (FR-10).
  final int watchedEpisodes;

  /// Aired episodes only. Counting unaired episodes would make a caught-up
  /// viewer permanently short of 100%.
  final int totalEpisodes;

  /// From the series' broadcast status (FR-07 field 7).
  final bool hasFinishedAiring;

  /// What the user declared in FR-09, if anything.
  final WatchStatus? userStatus;

  /// Remaining episodes — the brief requires this alongside the watched count
  /// (FR-10: "the system must compute the number of watched and remaining
  /// episodes").
  int get remainingEpisodes =>
      (totalEpisodes - watchedEpisodes).clamp(0, totalEpisodes);

  /// Fraction in `0.0 … 1.0`.
  double get fraction {
    if (totalEpisodes <= 0) return 0;
    return (watchedEpisodes / totalEpisodes).clamp(0.0, 1.0);
  }

  /// Whole percent, as the brief's worked example expects:
  /// 10 of 20 episodes → 50.
  int get percent => (fraction * 100).round();

  bool get isComplete => totalEpisodes > 0 && watchedEpisodes >= totalEpisodes;

  /// The FR-11 decision rule.
  ///
  /// Order matters. "Nothing watched" wins over everything, so an untouched
  /// series reads as black. Only then does completeness split green from
  /// purple.
  ProgressState get state {
    if (watchedEpisodes <= 0) return ProgressState.none;

    if (isComplete) {
      return hasFinishedAiring
          ? ProgressState
                .finishedComplete // بنفش
          : ProgressState.ongoingComplete; // سبز
    }

    return ProgressState.partial; // زرد
  }
}
