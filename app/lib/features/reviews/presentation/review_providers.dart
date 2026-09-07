import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../tracking/presentation/tracking_providers.dart';

/// Bumped after every rating or review change, so the distribution, the
/// review list, and the aggregate on the detail screen all refresh together.
///
/// A counter rather than a stream from the repository: ratings live in
/// Supabase now, and a REST client has nothing to push from.
final reviewRevisionProvider = StateProvider<int>((ref) => 0);

/// FR-13 — this user's own rating, or `null`.
final myRatingProvider = FutureProvider.family<int?, MediaKey>((
  ref,
  key,
) async {
  ref.watch(reviewRevisionProvider);
  final result = await ref
      .watch(reviewRepositoryProvider)
      .myRating(key.id, key.type);
  return result.valueOrNull;
});

/// FR-13 — the 1–5 star distribution, and the aggregate that feeds FR-06's
/// twelfth field.
final ratingSummaryProvider = FutureProvider.family<RatingSummary, MediaKey>((
  ref,
  key,
) async {
  ref.watch(reviewRevisionProvider);
  final result = await ref
      .watch(reviewRepositoryProvider)
      .ratingSummary(key.id, key.type);
  return result.valueOrNull ?? const RatingSummary.empty();
});

/// FR-14 — reviews for a title, newest first.
final reviewsProvider = FutureProvider.family<List<Review>, MediaKey>((
  ref,
  key,
) async {
  ref.watch(reviewRevisionProvider);
  final result = await ref
      .watch(reviewRepositoryProvider)
      .reviews(key.id, key.type);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// FR-19 statistic 6 — the mean of the ratings this user has submitted.
///
/// Read off the statistics rather than queried separately: both are the same
/// fold over the same rows.
final myAverageRatingProvider = FutureProvider<double?>((ref) async {
  final stats = await ref.watch(statisticsProvider.future);
  return stats.averageRating;
});
