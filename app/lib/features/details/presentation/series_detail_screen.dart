import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/watch_progress_bar.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/series.dart';
import '../../../router/app_router.dart';
import '../../reviews/presentation/widgets/rating_section.dart';
import '../../reviews/presentation/widgets/review_section.dart';
import '../../tracking/presentation/tracking_providers.dart';
import '../../tracking/presentation/widgets/tracking_bar.dart';
import 'detail_providers.dart';
import 'widgets/detail_widgets.dart';

/// FR-07 §5.7 — series details, and the entry point to FR-08's season and
/// episode lists.
class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({required this.seriesId, super.key});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seriesDetailProvider(seriesId));

    return Scaffold(
      appBar: AppBar(title: Text(async.valueOrNull?.name ?? '')),
      body: switch (async) {
        AsyncData(:final value) => _Body(series: value, ref: ref),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(seriesDetailProvider(seriesId)),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.series, required this.ref});

  final Series series;
  final WidgetRef ref;

  MediaSummary get _summary => MediaSummary(
    id: series.id,
    type: MediaType.series,
    title: series.name,
    posterPath: series.posterPath,
    overview: series.overview,
    releaseDate: series.firstAirDate,
    voteAverage: series.voteAverage,
  );

  @override
  Widget build(BuildContext context) {
    // Records the FR-11 denominator and broadcast state. Without this the
    // progress bar has no total to divide by, and green cannot be told from
    // purple.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingActionsProvider).rememberSeries(series);
    });

    // Season 0 holds specials. They are listed, but the brief's season and
    // episode counts refer to the numbered seasons, and counting specials
    // would make a fully caught-up viewer look incomplete in FR-11.
    final seasons = series.seasons.where((s) => !s.isSpecials).toList();

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
      children: [
        DetailHeader(
          title: series.name, // 1 · عنوان سریال
          subtitle: series.originalName,
          posterPath: series.posterPath, // 2 · پوستر
          backdropPath: series.backdropPath,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: RatingRow(
            externalRating: series.voteAverage, // 11 · امتیاز IMDb
            mediaKey: (id: series.id, type: MediaType.series),
          ),
        ),
        // FR-09 · FR-16 · FR-17
        TrackingBar(item: _summary),
        // FR-11 — percentage, remaining count, and the coloured bar.
        _ProgressSummary(seriesId: series.id),
        DetailSection(
          title: 'خلاصه داستان', // 3
          child: OverviewText(overview: series.overview),
        ),
        DetailSection(
          title: 'ژانر', // 4
          child: GenreChips(genres: series.genres),
        ),
        DetailSection(
          title: 'مشخصات',
          child: Column(
            children: [
              DetailFact(
                label: 'شروع پخش', // 5
                value: Formatters.year(series.firstAirDate),
              ),
              DetailFact(
                label: 'پایان پخش', // 6 — empty while still running
                value: series.lastAirDate == null || !series.hasFinishedAiring
                    ? '—'
                    : Formatters.year(series.lastAirDate),
              ),
              DetailFact(
                label: 'وضعیت پخش', // 7
                value: series.status.label,
              ),
              DetailFact(
                label: 'تعداد فصل‌ها', // 8
                value: series.numberOfSeasons.toPersian,
              ),
              DetailFact(
                label: 'تعداد قسمت‌ها', // 9
                value: series.numberOfEpisodes.toPersian,
              ),
            ],
          ),
        ),
        DetailSection(
          title: 'بازیگران', // 10
          child: CastRail(cast: series.cast),
        ),
        const Divider(height: AppSpacing.xl),
        // FR-13 — rating and its 0–100 distribution.
        RatingSection(item: _summary),
        // FR-14 · FR-15 — reviews and spoiler masking.
        ReviewSection(item: _summary),
        // ── FR-08 · seasons ───────────────────────────────────────────
        DetailSection(
          title: 'فصل‌ها',
          child: Column(
            children: [
              for (final season in seasons)
                _SeasonTile(seriesId: series.id, season: season),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeasonTile extends StatelessWidget {
  const _SeasonTile({required this.seriesId, required this.season});

  final int seriesId;
  final SeasonSummary season;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(season.name),
      subtitle: Text(
        '${season.episodeCount.toPersian} قسمت'
        '${season.airDate == null ? '' : ' · ${Formatters.year(season.airDate)}'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      // Chevron points to the start edge, which under RTL is the left —
      // the direction "forward" actually reads in Persian (NFR-11a).
      trailing: const Icon(Icons.chevron_left),
      onTap: () => context.goToSeason(seriesId, season.seasonNumber),
    );
  }
}

/// FR-11 §5.11 — the progress summary on the series screen.
///
/// The bar itself is also drawn across the lower portion of every poster (see
/// `PosterCard`); this is the expanded form, with the percentage and the
/// watched/remaining counts the brief asks FR-10 to compute.
class _ProgressSummary extends ConsumerWidget {
  const _ProgressSummary({required this.seriesId});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(seriesProgressProvider(seriesId)).valueOrNull;

    if (progress == null || progress.totalEpisodes == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'پیشرفت تماشا',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${progress.percent.toPersian}٪',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: WatchProgressBar.colorFor(progress.state),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: WatchProgressBar(progress: progress, height: 8),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${progress.watchedEpisodes.toPersian} از '
            '${progress.totalEpisodes.toPersian} قسمت دیده‌شده · '
            '${progress.remainingEpisodes.toPersian} باقی‌مانده',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
