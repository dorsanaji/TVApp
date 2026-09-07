import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/social/social_activity.dart';
import '../../../router/app_router.dart';
import 'social_providers.dart';

/// Task 3.3: the activity feed.
///
/// Real-time Letterboxd-style feed of recent watches, reviews and list
/// additions by the people the signed-in user follows, with Jalali relative
/// timestamps.
///
/// A bare view rather than a screen: it is a tab of `SocialScreen`, which
/// supplies the app bar.
class ActivityFeedView extends ConsumerWidget {
  const ActivityFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(activityFeedStreamProvider);

    return switch (feedAsync) {
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.dynamic_feed_outlined,
                message:
                    'هنوز فعالیتی از افراد دنبال‌شده وجود ندارد.\n'
                    'کاربران دیگر را دنبال کنید یا آثار جدید را در دفترچه تماشا ثبت کنید.',
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(activityFeedStreamProvider),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.bottomInset(context, extra: AppSpacing.lg),
                  ),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _ActivityCard(activity: value[index]),
                ),
              ),
      AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
          onRetry: () => ref.invalidate(activityFeedStreamProvider),
        ),
      _ => LoadingShimmer.listRows(),
    };
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final SocialActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A follow is about a person, not a title — there is no poster, no
    // rating and nothing to open. Rendering the media card for one produced
    // a placeholder that led to "film not found".
    final isAboutATitle = activity.actionType != SocialActionType.followed;

    final summary = MediaSummary(
      id: activity.movieId,
      type: activity.mediaType ?? MediaType.movie,
      title: activity.movieTitle ?? 'فیلم',
      posterPath: activity.moviePoster,
    );

    final rawAvatar = activity.userAvatar?.trim();
    final cleanAvatar = (rawAvatar != null &&
            rawAvatar.isNotEmpty &&
            rawAvatar != 'null')
        ? rawAvatar
        : null;
    final uname = activity.username?.trim();
    final uid = activity.userId.trim();
    final displayName = (uname != null && uname.isNotEmpty)
        ? uname
        : (uid.isNotEmpty ? uid : 'کاربر');
    final initial = displayName.isNotEmpty
        ? displayName.characters.first
        : '؟';

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. User Header & Relative Time ───────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/user/${activity.userId}'),
                  child: UserAvatar(
                    path: cleanAvatar,
                    initial: initial,
                    radius: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/user/${activity.userId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          Formatters.relativeTime(activity.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _actionIcon(activity.actionType),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 2. Persian Activity Summary ───────────────────────────
            Text(
              activity.toPersianSentence(),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            if (isAboutATitle) ...[
            const SizedBox(height: AppSpacing.sm),

            // ── 3. Movie Media Card & Rating / Review ─────────────────
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => context.goToDetail(summary),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    () {
                      final rawPoster = activity.moviePoster;
                      final cleanPoster = (rawPoster != null &&
                              rawPoster.trim().isNotEmpty &&
                              rawPoster.trim() != 'null')
                          ? rawPoster.trim()
                          : null;
                      final posterUrl = cleanPoster != null
                          ? (cleanPoster.startsWith('http')
                              ? cleanPoster
                              : 'https://image.tmdb.org/t/p/w185${cleanPoster.startsWith('/') ? cleanPoster : '/$cleanPoster'}')
                          : null;

                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: SizedBox(
                          width: 46,
                          height: 68,
                          child: posterUrl != null
                              ? Image.network(
                                  posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.movie,
                                    size: 28,
                                  ),
                                )
                              : const Icon(Icons.movie, size: 28),
                        ),
                      );
                    }(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.movieTitle ?? 'فیلم',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (activity.rating case final r?) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.star,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${r.toStringAsFixed(1).toPersianDigits} از ۵',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (activity.reviewText?.trim() case final review?
                              when review.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '«$review»',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _actionIcon(SocialActionType type) => switch (type) {
    SocialActionType.reviewed => Icons.rate_review_outlined,
    SocialActionType.watched => Icons.check_circle_outline,
    SocialActionType.addedToList => Icons.playlist_add_check,
    SocialActionType.favourited => Icons.favorite,
    SocialActionType.followed => Icons.person_add_alt_1_outlined,
    // Never reaches the feed — diary entries are filtered out upstream — but
    // the switch has to be total.
    SocialActionType.diary => Icons.menu_book_outlined,
  };
}
