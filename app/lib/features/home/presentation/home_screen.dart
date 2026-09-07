import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/media_carousel.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../router/app_router.dart';
import 'home_providers.dart';

/// FR-18 §5.18 — the main screen, carrying the five sections the brief names.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _sections = <(HomeSection, String)>[
    (HomeSection.popularMovies, AppStrings.sectionPopularMovies),
    (HomeSection.popularSeries, AppStrings.sectionPopularSeries),
    (HomeSection.newReleases, AppStrings.sectionNewReleases),
    (HomeSection.topRated, AppStrings.sectionTopRated),
    (HomeSection.suggestions, AppStrings.sectionSuggestions),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: AppStrings.navSearch,
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          for (final (section, _) in _sections) {
            ref.invalidate(homeSectionProvider(section));
          }
          // Wait for the sections to settle so the spinner reflects real work
          // rather than disappearing instantly.
          await Future.wait([
            for (final (section, _) in _sections)
              ref
                  .read(homeSectionProvider(section).future)
                  .catchError((Object _) => const <MediaSummary>[]),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            for (final (section, title) in _sections)
              _Section(section: section, title: title),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.section, required this.title});

  final HomeSection section;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeSectionProvider(section));

    return MediaCarousel(
      title: title,
      items: async.valueOrNull ?? const [],
      isLoading: async.isLoading,
      // The provider rethrows the original Failure, so its Persian message
      // survives all the way to the UI (FR-20).
      failure: async.error is Failure ? async.error! as Failure : null,
      onRetry: () => ref.invalidate(homeSectionProvider(section)),
      onItemTap: (item) => context.goToDetail(item),
    );
  }
}
