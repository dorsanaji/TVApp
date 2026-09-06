import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../router/app_router.dart';
import 'search_providers.dart';

/// FR-05 §5.5 — search.
///
/// Title search is the minimum the brief requires. The mode selector adds the
/// optional criteria it lists: by actor name, by director name (both served by
/// the person search), and by genre and release year.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final notifier = ref.read(searchQueryProvider.notifier);
    final results = ref.watch(searchResultsProvider);
    final paged = ref.watch(searchPaginationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                if (query.mode != SearchMode.filter)
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: notifier.setText,
                    decoration: InputDecoration(
                      hintText: query.mode == SearchMode.title
                          ? AppStrings.emptySearchPrompt
                          : 'نام بازیگر یا کارگردان',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _controller.clear();
                                notifier.clear();
                              },
                            ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                _ModeSelector(
                  mode: query.mode,
                  onChanged: (mode) {
                    _controller.clear();
                    notifier.setMode(mode);
                  },
                ),
                if (query.mode == SearchMode.filter) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const _Filters(),
                ],
              ],
            ),
          ),
          Expanded(
            child: _Results(query: query, results: results, paged: paged),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final SearchMode mode;
  final ValueChanged<SearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SearchMode>(
      segments: [
        for (final value in SearchMode.values)
          ButtonSegment(value: value, label: Text(value.label)),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// FR-05's genre and release-year criteria.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final notifier = ref.read(searchQueryProvider.notifier);
    final genres = ref.watch(genresProvider).valueOrNull ?? const [];

    // A fixed window of recent years covers the overwhelming majority of what
    // a user filters by; the year is otherwise better expressed as a search.
    const currentYear = 2026;
    final years = [for (var y = currentYear; y >= currentYear - 30; y--) y];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final genre in genres)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(genre.name),
                    selected: query.genreId == genre.id,
                    onSelected: (selected) =>
                        notifier.setGenre(selected ? genre.id : null),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final year in years)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(year.toString().toPersianDigits),
                    selected: query.year == year,
                    onSelected: (selected) =>
                        notifier.setYear(selected ? year : null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.results,
    required this.paged,
  });

  final SearchQuery query;
  final AsyncValue<SearchResults> results;
  final SearchResults paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const EmptyState(
        message: AppStrings.emptySearchPrompt,
        icon: Icons.search_rounded,
      );
    }

    return switch (results) {
      AsyncData(:final value) =>
        value.items.isEmpty
            // FR-05 acceptance: an empty result set is an explicit state, never
            // a blank screen.
            ? const EmptyState(
                message: AppStrings.emptyNoResults,
                icon: Icons.search_off_rounded,
              )
            : _Grid(paged: paged),
      AsyncError(:final error) => ErrorView(
        failure: error is Failure ? error : const FetchFailure(),
        onRetry: () => ref.invalidate(searchResultsProvider),
      ),
      _ => LoadingShimmer.listRows(),
    };
  }
}

/// NFR-04 — long lists load gradually rather than all at once.
class _Grid extends ConsumerWidget {
  const _Grid({required this.paged});

  final SearchResults paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = paged.items;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Fetch the next page while the user is still ~600px from the bottom,
        // so the new rows are in place before the scroll reaches them.
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 600) {
          ref.read(searchPaginationProvider.notifier).loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        // NFR-26: the column count follows the available width rather than a
        // fixed number, so the grid adapts from a small phone to a tablet.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.5,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return PosterCard(
            item: item,
            width: double.infinity,
            onTap: () => context.goToDetail(item),
          );
        },
      ),
    );
  }
}
