import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/bidi_text.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../domain/entities/episode.dart';
import '../../details/presentation/detail_providers.dart';
import '../../tracking/presentation/tracking_providers.dart';

/// FR-08 §5.8 — the episode list for one season, and FR-10 §5.10 — marking
/// episodes watched.
///
/// Each row carries the seven fields the brief names, the seventh being the
/// interactive watched state.
class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({
    required this.seriesId,
    required this.seasonNumber,
    super.key,
  });

  final int seriesId;
  final int seasonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (seriesId: seriesId, seasonNumber: seasonNumber);
    final async = ref.watch(seasonProvider(key));
    final watchedIds =
        ref.watch(watchedEpisodesProvider(seriesId)).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.name ?? 'فصل ${seasonNumber.toPersian}'),
        actions: [
          if (async.valueOrNull != null)
            _MarkSeasonButton(
              seriesId: seriesId,
              season: async.value!,
              watchedIds: watchedIds,
            ),
        ],
      ),
      body: switch (async) {
        AsyncData(:final value) =>
          value.episodes.isEmpty
              ? const EmptyState(
                  message: 'قسمتی برای این فصل ثبت نشده است',
                  icon: Icons.movie_filter_outlined,
                )
              : _EpisodeList(
                  seriesId: seriesId,
                  season: value,
                  watchedIds: watchedIds,
                ),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(seasonProvider(key)),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

/// FR-10's bulk action: "mark whole season watched".
class _MarkSeasonButton extends ConsumerWidget {
  const _MarkSeasonButton({
    required this.seriesId,
    required this.season,
    required this.watchedIds,
  });

  final int seriesId;
  final Season season;
  final Set<int> watchedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only aired episodes can be marked — an episode that has not been
    // broadcast cannot have been watched.
    final aired = season.episodes.where((e) => e.hasAired).toList();
    if (aired.isEmpty) return const SizedBox.shrink();

    final allWatched = aired.every((e) => watchedIds.contains(e.id));

    return TextButton.icon(
      onPressed: () => ref
          .read(trackingActionsProvider)
          .setSeasonWatched(
            seriesId: seriesId,
            seasonNumber: season.seasonNumber,
            episodeIds: aired.map((e) => e.id).toList(),
            runtimes: {for (final e in aired) e.id: e.runtime ?? 0},
            episodeNumbers: {for (final e in aired) e.id: e.episodeNumber},
            watched: !allWatched,
          ),
      icon: Icon(allWatched ? Icons.remove_done : Icons.done_all),
      label: Text(allWatched ? 'لغو همه' : 'همه دیده شد'),
    );
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({
    required this.seriesId,
    required this.season,
    required this.watchedIds,
  });

  final int seriesId;
  final Season season;
  final Set<int> watchedIds;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.bottomInset(context, extra: AppSpacing.lg),
      ),
      // Only visible rows are built (NFR-04). A season of 24 episodes is fine
      // either way, but the same list renders anthology seasons of 60+.
      itemCount: season.episodes.length + 1,
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.xl),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SeasonSummaryHeader(season: season, watchedIds: watchedIds);
        }
        final episode = season.episodes[index - 1];
        return _EpisodeTile(
          seriesId: seriesId,
          episode: episode,
          isWatched: watchedIds.contains(episode.id),
        );
      },
    );
  }
}

/// The watched and remaining counts FR-10 requires the system to compute.
class _SeasonSummaryHeader extends StatelessWidget {
  const _SeasonSummaryHeader({required this.season, required this.watchedIds});

  final Season season;
  final Set<int> watchedIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aired = season.episodes.where((e) => e.hasAired).toList();
    final watched = aired.where((e) => watchedIds.contains(e.id)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '${aired.length.toPersian} قسمت پخش‌شده',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '${watched.toPersian} دیده‌شده · '
            '${(aired.length - watched).toPersian} باقی‌مانده',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
    required this.seriesId,
    required this.episode,
    required this.isWatched,
  });

  final int seriesId;
  final Episode episode;
  final bool isWatched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unaired = !episode.hasAired;

    return Opacity(
      // An unaired episode is shown but inactive: it cannot be marked watched,
      // and it is excluded from the FR-11 denominator.
      opacity: unaired ? 0.5 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      // 1 · شماره فصل  ·  2 · شماره قسمت
                      episode.code.toPersianDigits,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        episode.name, // 3 · عنوان قسمت
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // 4 · تاریخ انتشار  ·  5 · مدت زمان
                  '${Formatters.jalaliDate(episode.airDate)}'
                  '${episode.runtime == null ? '' : ' · ${Formatters.runtime(episode.runtime)}'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (episode.overview != null &&
                    episode.overview!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  BidiText(
                    episode.overview!, // 6 · خلاصه قسمت
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 7 · وضعیت مشاهده شدن — FR-10.
          Checkbox(
            value: isWatched,
            onChanged: unaired
                ? null
                : (value) => ref
                      .read(trackingActionsProvider)
                      .setEpisodeWatched(
                        seriesId: seriesId,
                        episodeId: episode.id,
                        seasonNumber: episode.seasonNumber,
                        episodeNumber: episode.episodeNumber,
                        runtimeMinutes: episode.runtime ?? 0,
                        watched: value ?? false,
                      ),
          ),
        ],
      ),
    );
  }
}
