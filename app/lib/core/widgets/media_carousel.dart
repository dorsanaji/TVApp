import 'package:flutter/material.dart';

import '../../domain/entities/media_summary.dart';
import '../error/failure.dart';
import '../theme/app_spacing.dart';
import 'empty_state.dart';
import 'error_view.dart';
import 'loading_shimmer.dart';
import 'poster_card.dart';
import 'section_header.dart';

/// A titled horizontal rail of posters — the building block of the FR-18 home
/// screen.
///
/// Handles its own loading, error, and empty states so that one failing
/// section never takes the screen down with it (NFR-12, FR-20).
class MediaCarousel extends StatelessWidget {
  const MediaCarousel({
    required this.title,
    required this.items,
    required this.isLoading,
    required this.failure,
    required this.onRetry,
    required this.onItemTap,
    super.key,
  });

  final String title;
  final List<MediaSummary> items;
  final bool isLoading;
  final Failure? failure;
  final VoidCallback onRetry;
  final void Function(MediaSummary item) onItemTap;

  static const _railHeight =
      AppSpacing.posterCardWidth / AppSpacing.posterAspectRatio + 56;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(height: _railHeight, child: _body()),
      ],
    );
  }

  Widget _body() {
    if (isLoading) return LoadingShimmer.posterRow();

    if (failure != null) {
      return _Compact(
        child: ErrorView(failure: failure!, onRetry: onRetry),
      );
    }

    if (items.isEmpty) {
      return const _Compact(
        child: EmptyState(message: 'موردی برای نمایش نیست'),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      // NFR-04/NFR-40: only the visible cards are built and only their images
      // are requested, so scrolling a long rail does not download the whole of
      // it up front.
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = items[index];
        return PosterCard(item: item, onTap: () => onItemTap(item));
      },
    );
  }
}

/// Shrinks the shared error/empty views to fit inside a rail, where the
/// full-screen layout would overflow.
class _Compact extends StatelessWidget {
  const _Compact({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: 320, child: child),
      ),
    );
  }
}
