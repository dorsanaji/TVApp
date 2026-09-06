import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/movie.dart';
import '../../reviews/presentation/widgets/rating_section.dart';
import '../../reviews/presentation/widgets/review_section.dart';
import '../../tracking/presentation/tracking_providers.dart';
import '../../tracking/presentation/widgets/tracking_bar.dart';
import 'detail_providers.dart';
import 'widgets/detail_widgets.dart';

/// FR-06 §5.6 — film details.
///
/// The `_Facts` block below renders the brief's twelve fields in the order the
/// brief lists them, so the screen can be checked against §5.6 line by line.
class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({required this.movieId, super.key});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(movieDetailProvider(movieId));

    return Scaffold(
      appBar: AppBar(title: Text(async.valueOrNull?.title ?? '')),
      body: switch (async) {
        AsyncData(:final value) => _Body(movie: value, ref: ref),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(movieDetailProvider(movieId)),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.movie, required this.ref});

  final Movie movie;
  final WidgetRef ref;

  MediaSummary get _summary => MediaSummary(
    id: movie.id,
    type: MediaType.movie,
    title: movie.title,
    posterPath: movie.posterPath,
    overview: movie.overview,
    releaseDate: movie.releaseDate,
    voteAverage: movie.voteAverage,
  );

  @override
  Widget build(BuildContext context) {
    // Cache runtime and genres now, so the FR-19 watch-time and
    // favourite-genre statistics can be computed later without re-fetching
    // every film the user has ever marked watched (NFR-42).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(trackingActionsProvider)
          .rememberMovie(
            _summary,
            runtimeMinutes: movie.runtime ?? 0,
            genres: movie.genres.map((g) => g.name).toList(),
          );
    });

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
      children: [
        DetailHeader(
          title: movie.title, // 1 · عنوان فیلم
          subtitle: movie.originalTitle, // 2 · عنوان اصلی
          posterPath: movie.posterPath, // 3 · پوستر
          backdropPath: movie.backdropPath,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: RatingRow(
            externalRating: movie.voteAverage, // 11 · امتیاز IMDb
            // 12 · امتیاز کاربران اپلیکیشن — aggregated from the local ratings.
            mediaKey: (id: movie.id, type: MediaType.movie),
          ),
        ),
        // FR-09 · FR-16 · FR-17
        TrackingBar(item: _summary),
        DetailSection(
          title: 'خلاصه داستان', // 4
          child: OverviewText(overview: movie.overview),
        ),
        DetailSection(
          title: 'ژانر', // 7
          child: GenreChips(genres: movie.genres),
        ),
        DetailSection(
          title: 'مشخصات',
          child: Column(
            children: [
              DetailFact(
                label: 'سال انتشار', // 5
                value: Formatters.year(movie.releaseDate),
              ),
              DetailFact(
                label: 'مدت زمان', // 6
                value: Formatters.runtime(movie.runtime),
              ),
              DetailFact(
                label: 'کشور سازنده', // 8
                value: movie.productionCountries.join('، '),
              ),
              DetailFact(
                label: 'کارگردان', // 9
                value: movie.directors.map((d) => d.name).join('، '),
              ),
            ],
          ),
        ),
        DetailSection(
          title: 'بازیگران', // 10
          child: CastRail(cast: movie.cast),
        ),
        const Divider(height: AppSpacing.xl),
        // FR-13 — rating and its 0–100 distribution.
        RatingSection(item: _summary),
        // FR-14 · FR-15 — reviews and spoiler masking.
        ReviewSection(item: _summary),
      ],
    );
  }
}
