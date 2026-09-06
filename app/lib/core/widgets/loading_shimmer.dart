import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_spacing.dart';

/// Skeleton placeholders shown while data loads.
///
/// NM-04 and NFR-12 both require the loading state to be visible. A skeleton
/// is preferred to a bare spinner because it also communicates the shape of
/// what is arriving, which keeps the screen from jumping when it does.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerHigh,
      child: child,
    );
  }

  /// A row of poster placeholders, matching the home-screen carousels (FR-18).
  static Widget posterRow({int count = 4}) => SizedBox(
    height: AppSpacing.posterCardWidth / AppSpacing.posterAspectRatio + 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, _) => LoadingShimmer(
        child: Container(
          width: AppSpacing.posterCardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    ),
  );

  /// A vertical list of row placeholders, for search results and episodes.
  static Widget listRows({int count = 6}) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.lg),
    itemCount: count,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (context, _) => LoadingShimmer(
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
  );
}
