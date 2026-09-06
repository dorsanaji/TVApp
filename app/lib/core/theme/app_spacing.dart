import 'package:flutter/widgets.dart';

/// Spacing and sizing tokens.
///
/// Fixed steps rather than ad-hoc numbers, so screens stay visually
/// consistent across different phones (NFR-26, NFR-27).
abstract final class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;

  /// Poster aspect ratio used by TMDB artwork.
  static const posterAspectRatio = 2 / 3;

  /// Card width in horizontal carousels.
  static const posterCardWidth = 120.0;

  /// Height of the FR-11 progress bar drawn across the bottom of a poster.
  static const progressBarHeight = 5.0;

  /// Bottom padding for a scrollable on a **full-screen route** — one with no
  /// bottom navigation bar to reserve the space for it.
  ///
  /// Android's navigation bar is 24–48dp depending on whether the phone uses
  /// gestures or three buttons, and a fixed padding cannot cover both: the
  /// detail screens padded 32dp and their last rows sat under the system bar
  /// on a gesture phone. Adding the real inset fixes it on every device
  /// (NFR-26, NFR-27).
  ///
  /// Tab screens must **not** use this — `Scaffold` already keeps its body
  /// clear of `bottomNavigationBar`, which carries the inset itself, so adding
  /// it again would double-pad.
  static double bottomInset(BuildContext context, {double extra = xxl}) =>
      MediaQuery.viewPaddingOf(context).bottom + extra;
}
