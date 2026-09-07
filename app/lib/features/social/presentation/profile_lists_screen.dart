import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
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
import '../../../domain/entities/social/public_profile.dart';
import '../../../domain/entities/social/social_activity.dart';
import 'social_providers.dart';

/// Which side of the follow relationship a [FollowListScreen] shows.
enum FollowListKind {
  followers('دنبال‌کننده‌ها'),
  following('دنبال‌شده‌ها');

  const FollowListKind(this.title);

  final String title;
}

/// The people following a user, or the people they follow.
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    required this.userId,
    required this.kind,
    super.key,
  });

  final String userId;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = switch (kind) {
      FollowListKind.followers => ref.watch(followersProvider(userId)),
      FollowListKind.following => ref.watch(followingProvider(userId)),
    };

    return Scaffold(
      appBar: AppBar(title: Text(kind.title)),
      body: switch (async) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: Icons.people_outline,
                message: switch (kind) {
                  FollowListKind.followers => 'هنوز کسی این کاربر را دنبال نکرده است',
                  FollowListKind.following => 'این کاربر هنوز کسی را دنبال نکرده است',
                },
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.bottomInset(context, extra: AppSpacing.lg),
                ),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _ProfileTile(
                  profile: value[index],
                ),
              ),
        AsyncError(:final error) => ErrorView(
            failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
            onRetry: () => ref
              ..invalidate(followersProvider(userId))
              ..invalidate(followingProvider(userId)),
          ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.username.trim();
    final displayName = name.isNotEmpty ? name : 'کاربر';
    final bio = profile.bio?.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: UserAvatar(
          path: profile.avatarUrl,
          initial: displayName.characters.first,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: bio != null && bio.isNotEmpty
            ? Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis)
            : Text('${profile.totalWatched.toPersian} اثر دیده‌شده'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push('/user/${profile.userId}'),
      ),
    );
  }
}

/// Everything a user has marked watched — the list behind the profile's
/// watched count.
class WatchedTitlesScreen extends ConsumerWidget {
  const WatchedTitlesScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userWatchedTitlesProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('فیلم‌ها و سریال‌های دیده‌شده')),
      body: switch (async) {
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.movie_outlined,
                message: 'هنوز اثری به عنوان دیده‌شده ثبت نشده است',
              )
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.bottomInset(context, extra: AppSpacing.lg),
                ),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.58,
                ),
                itemCount: value.length,
                itemBuilder: (context, index) =>
                    ActivityPoster(activity: value[index]),
              ),
        AsyncError(:final error) => ErrorView(
            failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
            onRetry: () => ref.invalidate(userActivitiesProvider(userId)),
          ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

/// A poster for a title carried on an activity row.
///
/// Activity rows only remember a poster path and a title, so this cannot use
/// `PosterCard` — there is no `MediaSummary` behind them. The film/series
/// distinction rides in the activity id, and rows written before that was
/// recorded fall back to the film route.
class ActivityPoster extends StatelessWidget {
  const ActivityPoster({required this.activity, this.width, super.key});

  final SocialActivity activity;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = Env.imageUrl(activity.moviePoster);

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => context.push(
          activity.mediaType == MediaType.series
              ? '/series/${activity.movieId}'
              : '/movie/${activity.movieId}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: _Poster(url: url, theme: theme),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              activity.movieTitle ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.theme});

  final String? url;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.movie_outlined, size: 28)),
    );

    if (url == null) return fallback;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}


/// The full diary: everything a user did, newest first, with dates.
///
/// Its own screen rather than a block inside the profile — a scrollable
/// record of every action crowded out the sections around it.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userDiaryProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('دفترچه فعالیت')),
      body: switch (async) {
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                message: 'هنوز چیزی در دفترچه تماشا ثبت نشده است',
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.bottomInset(context, extra: AppSpacing.lg),
                ),
                itemCount: value.length,
                separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
                itemBuilder: (context, index) =>
                    DiaryEntry(activity: value[index]),
              ),
        AsyncError(:final error) => ErrorView(
            failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
            onRetry: () => ref.invalidate(userActivitiesProvider(userId)),
          ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

/// One dated diary entry: when, what, how many stars, and the note.
class DiaryEntry extends StatelessWidget {
  const DiaryEntry({required this.activity, super.key});

  final SocialActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = activity.reviewText?.trim();
    final stars = activity.rating?.round() ?? 0;

    return InkWell(
      onTap: () => context.push(
        activity.mediaType == MediaType.series
            ? '/series/${activity.movieId}'
            : '/movie/${activity.movieId}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 46,
                height: 68,
                child: _Poster(
                  url: Env.imageUrl(activity.moviePoster),
                  theme: theme,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The date leads: a diary is read by when things happened.
                  Text(
                    Formatters.formatJalaliDate(activity.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.movieTitle ?? 'اثر',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (stars > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: AppColors.star,
                          ),
                      ],
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note,
                      style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }
}
