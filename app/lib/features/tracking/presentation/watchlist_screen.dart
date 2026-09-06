import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../../router/app_router.dart';
import '../../auth/presentation/auth_providers.dart';
import 'tracking_providers.dart';

/// FR-12 §5.12 — the watchlist, with the four sections the brief names, and
/// FR-16's favourites as the fourth of them.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  static const _tabs = <(WatchlistSection, String)>[
    (WatchlistSection.watching, AppStrings.watchlistWatching),
    (WatchlistSection.watched, AppStrings.watchlistWatched),
    (WatchlistSection.watchLater, AppStrings.watchlistLater),
    (WatchlistSection.favourites, AppStrings.watchlistFavourites),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSignedInProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.navWatchlist)),
        body: const SignInRequired(
          message:
              'برای ثبت وضعیت تماشا و ساختن فهرست تماشا\nوارد حساب خود شوید',
        ),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.navWatchlist),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (_, label) in _tabs) Tab(text: label)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final (section, _) in _tabs) _Section(section: section),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.section});

  final WatchlistSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchlistProvider(section));

    return switch (async) {
      AsyncData(:final value) =>
        value.isEmpty
            ? const EmptyState(
                message: AppStrings.emptyWatchlist,
                icon: Icons.bookmark_border,
              )
            : _Grid(items: value, section: section),
      AsyncError(:final error) => ErrorView(
        failure: error is Failure ? error : const FetchFailure(),
        onRetry: () => ref.invalidate(watchlistProvider(section)),
      ),
      _ => LoadingShimmer.listRows(),
    };
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.items, required this.section});

  final List<MediaSummary> items;
  final WatchlistSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FR-11 — one query for the progress of every series on screen, rather
    // than one per card.
    final seriesIds = items
        .where((i) => i.type.isSeries)
        .map((i) => i.id)
        .toList();
    final progress =
        ref.watch(progressForAllProvider(seriesIds)).valueOrNull ?? const {};

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return _Removable(
          item: item,
          section: section,
          child: PosterCard(
            item: item,
            width: double.infinity,
            progress: progress[item.id],
            onTap: () => context.goToDetail(item),
          ),
        );
      },
    );
  }
}

/// Long-press to remove, with an undo.
///
/// FR-12 requires removal; the confirmation-plus-undo pattern is what keeps an
/// accidental removal from silently destroying tracked progress (NFR-20).
class _Removable extends ConsumerWidget {
  const _Removable({
    required this.item,
    required this.section,
    required this.child,
  });

  final MediaSummary item;
  final WatchlistSection section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _remove(context, ref),
      child: child,
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(trackingActionsProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Captured before removal so the exact prior state can be restored.
    final previousStatus = ref
        .read(watchStatusProvider((id: item.id, type: item.type)))
        .valueOrNull;

    if (section == WatchlistSection.favourites) {
      await actions.toggleFavourite(item, favourite: false);
    } else {
      await actions.setStatus(item, null);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('«${item.title}» حذف شد'),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () async {
            if (section == WatchlistSection.favourites) {
              await actions.toggleFavourite(item, favourite: true);
            } else {
              await actions.setStatus(
                item,
                previousStatus ?? section.status ?? WatchStatus.planToWatch,
              );
            }
          },
        ),
      ),
    );
  }
}
