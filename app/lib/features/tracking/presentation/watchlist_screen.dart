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
    (WatchlistSection.watchLater, AppStrings.watchlistLater),
    (WatchlistSection.favourites, AppStrings.watchlistFavourites),
    (WatchlistSection.watched, AppStrings.watchlistWatched),
    (WatchlistSection.watching, AppStrings.watchlistWatching),
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

/// Which kinds of title the "watched" section shows.
enum WatchedFilter {
  all('همه'),
  movies('فیلم‌ها'),
  series('سریال‌ها');

  const WatchedFilter(this.label);

  final String label;

  bool matches(MediaSummary item) => switch (this) {
    WatchedFilter.all => true,
    WatchedFilter.movies => item.type.isMovie,
    WatchedFilter.series => item.type.isSeries,
  };
}

/// The film/series choice, per section.
///
/// Keyed by section so each keeps its own: someone narrowing «موردعلاقه‌ها»
/// to series has said nothing about how they want «مشاهده شده» shown. Held
/// outside the tab so the choice survives switching away and back.
///
/// «در حال تماشا» has no entry — only series can be in progress, so a filter
/// there would offer a choice between everything and nothing.
final watchedFilterProvider =
    StateProvider.family<WatchedFilter, WatchlistSection>(
  (ref, section) => WatchedFilter.all,
);

/// Whether [section] is worth offering a film/series filter for.
bool _isFilterable(WatchlistSection section) =>
    section == WatchlistSection.watched ||
    section == WatchlistSection.watchLater ||
    section == WatchlistSection.favourites;

class _Section extends ConsumerWidget {
  const _Section({required this.section});

  final WatchlistSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchlistProvider(section));
    final filterable = _isFilterable(section);
    final filter = ref.watch(watchedFilterProvider(section));

    Widget withFilter(Widget child) {
      if (!filterable) return child;
      return Column(
        children: [
          _WatchedFilterBar(section: section, selected: filter),
          Expanded(child: child),
        ],
      );
    }

    return switch (async) {
      AsyncData(:final value) => () {
        final items = filterable
            ? value.where(filter.matches).toList()
            : value;

        if (items.isEmpty) {
          return withFilter(
            EmptyState(
              message: filterable && filter != WatchedFilter.all
                  ? 'در این بخش ${filter.label} ندارید'
                  : AppStrings.emptyWatchlist,
              icon: Icons.bookmark_border,
            ),
          );
        }

        return withFilter(_Grid(items: items, section: section));
      }(),
      AsyncError(:final error) => ErrorView(
        failure: error is Failure ? error : const FetchFailure(),
        onRetry: () => ref.invalidate(watchlistProvider(section)),
      ),
      _ => LoadingShimmer.listRows(),
    };
  }
}

/// Films / series / both, for one section of the watchlist.
class _WatchedFilterBar extends ConsumerWidget {
  const _WatchedFilterBar({required this.section, required this.selected});

  final WatchlistSection section;
  final WatchedFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          for (final filter in WatchedFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: filter == selected,
              onSelected: (_) => ref
                  .read(watchedFilterProvider(section).notifier)
                  .state = filter,
            ),
            if (filter != WatchedFilter.values.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
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
