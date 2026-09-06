import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/media_summary.dart';

/// The five sections FR-18 §5.18 requires on the main screen.
enum HomeSection {
  popularMovies,
  popularSeries,
  newReleases,
  topRated,
  suggestions,
}

/// One provider per section, each fetching independently.
///
/// Independence is the point: a slow or failing section shows its own error
/// with a retry while the other four render normally. A single provider
/// returning all five would make one upstream hiccup blank the whole screen,
/// which NFR-01 and FR-20 both argue against.
final homeSectionProvider = FutureProvider.family<List<MediaSummary>, HomeSection>((
  ref,
  section,
) async {
  final repository = ref.watch(catalogRepositoryProvider);

  final result = switch (section) {
    HomeSection.popularMovies => await repository.popularMovies(),
    HomeSection.popularSeries => await repository.popularSeries(),
    HomeSection.newReleases => await repository.newReleases(),
    HomeSection.topRated => await repository.topRated(),
    // With no signed-in user yet (Phase 4), suggestions fall back to trending.
    // Once tracking exists this is seeded from the user's most recent title.
    HomeSection.suggestions => await repository.recommendations(),
  };

  return switch (result) {
    Ok(:final value) => value.items,
    // Rethrowing lets Riverpod's AsyncValue carry the failure to the UI, where
    // ErrorView renders its Persian message. The Failure type is preserved, so
    // nothing is degraded to a generic error on the way.
    Err(:final failure) => throw failure,
  };
});
