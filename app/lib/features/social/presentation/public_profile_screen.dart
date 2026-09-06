import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../../domain/entities/social/public_profile.dart';
import '../../../domain/entities/social/social_activity.dart';
import '../../auth/presentation/auth_providers.dart';
import 'social_providers.dart';

/// Task 3.1: PublicProfileScreen.
///
/// Shows public user stats, public custom lists, and a Follow/Unfollow button.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull ??
        ref.watch(authRepositoryProvider).currentUserOrNull;
    final currentUserId = currentUser?.id;
    final isOwnProfile = currentUserId != null &&
        (currentUserId == userId ||
            currentUserId == profileAsync.valueOrNull?.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(profileAsync.valueOrNull?.username ?? 'پروفایل کاربر'),
      ),
      body: switch (profileAsync) {
        AsyncData(:final value) => _ProfileContent(
            profile: value,
            isOwnProfile: isOwnProfile,
            routeUserId: userId,
          ),
        AsyncError(:final error) => ErrorView(
            failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
            onRetry: () => ref.invalidate(publicProfileProvider(userId)),
          ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.isOwnProfile,
    required this.routeUserId,
  });

  final PublicProfile profile;
  final bool isOwnProfile;
  final String routeUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activitiesAsync =
        ref.watch(userWatchedActivitiesProvider(profile.userId));
    final listsAsync = ref.watch(userPublicListsProvider(profile.userId));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.bottomInset(context, extra: AppSpacing.lg),
      ),
      children: [
        // ── 1. User Header & Avatar ──────────────────────────────────
        Center(
          child: Column(
            children: [
              () {
                final rawAvatar = profile.avatarUrl?.trim();
                final cleanAvatar = (rawAvatar != null &&
                        rawAvatar.isNotEmpty &&
                        rawAvatar != 'null')
                    ? rawAvatar
                    : null;
                final uname = profile.username.trim();
                final displayName = uname.isNotEmpty ? uname : 'کاربر';
                final initial = displayName.isNotEmpty
                    ? displayName.characters.first
                    : '؟';
                final bio = profile.bio?.trim();

                return Column(
                  children: [
                    UserAvatar(
                      path: cleanAvatar,
                      initial: initial,
                      radius: 44,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );
              }(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 2. Follow / Following Counts & Action ─────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(
              label: 'دنبال‌کننده‌ها',
              value: profile.followersCount.toPersian,
            ),
            _StatColumn(
              label: 'دنبال‌شده‌ها',
              value: profile.followingCount.toPersian,
            ),
            _StatColumn(
              label: 'فیلم‌های دیده‌شده',
              value: profile.totalWatched.toPersian,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Follow / Unfollow Button
        if (!isOwnProfile)
          Center(
            child: SizedBox(
              width: 200,
              child: profile.isFollowing
                  ? OutlinedButton.icon(
                      onPressed: () async {
                        final res = await ref
                            .read(socialActionsProvider)
                            .toggleFollow(profile.userId, follow: false);
                        if (context.mounted && res.isErr) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.failureOrNull?.message ?? 'خطا در عملیات'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        ref.invalidate(publicProfileProvider(routeUserId));
                        ref.invalidate(publicProfileProvider(profile.userId));
                        ref.invalidate(myFollowedUserIdsProvider);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('دنبال می‌کنید'),
                    )
                  : FilledButton.icon(
                      onPressed: () async {
                        final signedIn = ref.read(isSignedInProvider);
                        if (!signedIn) {
                          showSignInPrompt(context, action: 'دنبال کردن کاربران');
                          return;
                        }
                        final res = await ref
                            .read(socialActionsProvider)
                            .toggleFollow(profile.userId, follow: true);
                        if (context.mounted && res.isErr) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.failureOrNull?.message ?? 'خطا در عملیات'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        ref.invalidate(publicProfileProvider(routeUserId));
                        ref.invalidate(publicProfileProvider(profile.userId));
                        ref.invalidate(myFollowedUserIdsProvider);
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('دنبال کردن'),
                    ),
            ),
          ),
        const Divider(height: AppSpacing.xxl),

        // ── 3. Quick Stats Grid ───────────────────────────────────────
        Text(
          'خلاصه فعالیت',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.0,
          children: [
            _StatCard(
              icon: Icons.movie_outlined,
              label: 'مجموع تماشا',
              value: '${profile.totalWatched.toPersian} اثر',
            ),
            _StatCard(
              icon: Icons.category_outlined,
              label: 'ژانر موردعلاقه',
              value: profile.favoriteGenre ?? 'نامشخص',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── 3.5. Watched Titles & Notes ──────────────────────────────
        Text(
          'آثار تماشاشده و یادداشت‌ها',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (activitiesAsync) {
          AsyncData(:final value) => () {
              // Deduplicate by movieId to eliminate any repeat/spam posters
              final uniqueActs = <int, SocialActivity>{};
              for (final act in value) {
                uniqueActs.putIfAbsent(act.movieId, () => act);
              }
              final displayList = uniqueActs.values.toList();

              if (displayList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'هنوز فیلم یا سریالی ثبت نشده است.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return SizedBox(
                height: 145,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayList.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                      final act = displayList[index];
                      final rawPoster = act.moviePoster;
                      final cleanPoster = (rawPoster != null &&
                              rawPoster.trim().isNotEmpty &&
                              rawPoster.trim() != 'null')
                          ? rawPoster.trim()
                          : null;
                      final posterUrl =
                          cleanPoster != null ? Env.imageUrl(cleanPoster) : null;
                      return SizedBox(
                        width: 82,
                        child: InkWell(
                          onTap: () => context.push('/movie/${act.movieId}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                child: (posterUrl != null &&
                                        posterUrl.trim().isNotEmpty &&
                                        posterUrl.trim() != 'null')
                                    ? CachedNetworkImage(
                                        imageUrl: posterUrl.trim(),
                                        width: 82,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(
                                          width: 82,
                                          height: 110,
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.movie,
                                            size: 28,
                                          ),
                                        ),
                                        errorWidget: (_, _, _) => Container(
                                          width: 82,
                                          height: 110,
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.movie,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 82,
                                        height: 110,
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.movie,
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                act.movieTitle ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }(),
          _ => const SizedBox.shrink(),
        },
        const SizedBox(height: AppSpacing.xl),

        // ── 4. Public Custom Lists ────────────────────────────────────
        Text(
          'فهرست‌های عمومی کاربر',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (listsAsync) {
          AsyncData(:final value) => value.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.playlist_remove,
                    message: 'این کاربر هنوز فهرست عمومی نساخته است',
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final list = value[index];
                    final rawCover = list.coverPath;
                    final cleanCover = (rawCover != null &&
                            rawCover.trim().isNotEmpty &&
                            rawCover.trim() != 'null')
                        ? rawCover.trim()
                        : null;
                    final cover =
                        cleanCover != null ? Env.imageUrl(cleanCover) : null;
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          child: SizedBox(
                            width: 44,
                            height: 60,
                            child: (cover != null &&
                                    cover.trim().isNotEmpty &&
                                    cover.trim() != 'null')
                                ? CachedNetworkImage(
                                    imageUrl: cover.trim(),
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.movie_outlined, size: 24),
                                    ),
                                    errorWidget: (_, _, _) => Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.movie, size: 24),
                                    ),
                                  )
                                : Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.playlist_play, size: 32),
                                  ),
                          ),
                        ),
                        title: Text(
                          list.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${list.itemCount.toPersian} اثر'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push(
                          '/collaborative-list/${list.listId}',
                        ),
                      ),
                    );
                  },
                ),
          AsyncError(:final error) => Text(
              error is Failure ? error.message : 'خطا در بارگذاری فهرست‌ها',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          _ => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
        },
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
