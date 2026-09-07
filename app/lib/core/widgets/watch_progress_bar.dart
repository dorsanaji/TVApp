import 'package:flutter/material.dart';

import '../../domain/entities/watch_progress.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// FR-11 §5.11 — the watch-progress bar.
///
/// The brief asks for three things and this widget delivers all three:
///
///  1. the percentage (`watched / total × 100`);
///  2. a bar drawn **across the lower portion of the poster**, whose **width
///     is proportional** to that percentage;
///  3. **five colour states**, each with a defined meaning.
///
/// The colour decision itself lives in [WatchProgress.state] rather than here,
/// so it is unit-testable without pumping a widget — see
/// `test/domain/watch_progress_test.dart`, which covers every branch.
class WatchProgressBar extends StatelessWidget {
  const WatchProgressBar({
    required this.progress,
    this.height = AppSpacing.progressBarHeight,
    super.key,
  });

  final WatchProgress progress;
  final double height;

  /// Maps the domain state onto the colours the brief prescribes by name.
  static Color colorFor(ProgressState state) => switch (state) {
    ProgressState.none => AppColors.progressNone, // بی‌رنگ یا مشکی
    ProgressState.ongoingComplete => AppColors.progressOngoing, // سبز
    ProgressState.finishedComplete => AppColors.progressCompleted, // بنفش
    ProgressState.partial => AppColors.progressPartial, // زرد
  };

  @override
  Widget build(BuildContext context) {
    final state = progress.state;
    final color = colorFor(state);

    // Nothing tracked at all: no series, or a film, which has no episodes to
    // progress through. Drawing an empty track would imply tracking that is
    // not happening.
    if (progress.totalEpisodes <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Unfilled track, so the bar reads as "x of y" rather than as a
          // free-floating stripe.
          ColoredBox(color: AppColors.progressNone.withValues(alpha: 0.85)),
          // The filled portion. FractionallySizedBox makes the width
          // proportional, and it resolves `start` correctly under RTL.
          //
          // `heightFactor: 1` is load-bearing, not decoration. With only a
          // width factor the child receives a *tight width but a loose
          // height*, and a childless ColoredBox then collapses to zero — so
          // the bar painted 40% wide and 0px tall, showing nothing at all
          // while the percentage above it correctly read ۴۰٪.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress.fraction,
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
