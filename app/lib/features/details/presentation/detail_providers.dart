import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/entities/series.dart';

/// FR-06 — one film's full detail.
final movieDetailProvider = FutureProvider.family<Movie, int>((ref, id) async {
  final result = await ref.watch(catalogRepositoryProvider).movieDetails(id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// FR-07 — one series' full detail, including its season stubs.
final seriesDetailProvider = FutureProvider.family<Series, int>((
  ref,
  id,
) async {
  final result = await ref.watch(catalogRepositoryProvider).seriesDetails(id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// FR-08 — one season with its episodes.
///
/// Keyed by (series, season) so each is fetched only when the user opens it,
/// which is what keeps a 15-season series from costing 15 requests on open
/// (NFR-04, NM-08).
typedef SeasonKey = ({int seriesId, int seasonNumber});

final seasonProvider = FutureProvider.family<Season, SeasonKey>((
  ref,
  key,
) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .season(key.seriesId, key.seasonNumber);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
