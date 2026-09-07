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
import 'profile_lists_screen.dart';
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
    final profile = profileAsync.valueOrNull;
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
      // Keep showing the profile we already have while a refresh is in
      // flight. Falling back to the shimmer on every refetch tore down the
      // follow button along with the rest of the page, throwing away its
      // optimistic state and making a fresh tap look like it had been ignored.
      body: profile != null
          ? _ProfileContent(
              profile: profile,
              isOwnProfile: isOwnProfile,
              routeUserId: userId,
            )
          : switch (profileAsync) {
              AsyncError(:final error) => ErrorView(
                  failure:
                      error is Failure ? error : ErrorMapper.fromUnknown(error),
                  onRetry: () => ref.invalidate(publicProfileProvider(userId)),
                ),
              _ => LoadingShimmer.listRows(),
            },
    );
  }
}

/// Follow / unfollow control.
///
/// The button keeps its own idea of the follow state from the moment it is
/// tapped. Following writes to Supabase and then re-reads the profile, which
/// is several round trips; driving the label straight off the provider meant
/// the button sat on the old label until all of that finished, so a tap looked
/// like it had done nothing and the state only looked right after leaving the
/// page and coming back.
class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.profile, required this.routeUserId});

  final PublicProfile profile;

  /// The id this screen was routed with. It can be a username, whereas the
  /// action resolves to the canonical id — so the two are invalidated
  /// separately or the visible copy keeps its stale value.
  final String routeUserId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;

    if (!ref.read(isSignedInProvider)) {
      showSignInPrompt(context, action: 'دنبال کردن کاربران');
      return;
    }

    final pendingFollow = pendingFollowProvider(widget.profile.userId);
    final wantFollow =
        !(ref.read(pendingFollow) ?? widget.profile.isFollowing);

    ref.read(pendingFollow.notifier).state = wantFollow;
    setState(() => _busy = true);

    final res = await ref
        .read(socialActionsProvider)
        .toggleFollow(widget.profile.userId, follow: wantFollow);

    if (!mounted) return;

    if (res.isErr) {
      // Put the button — and the count that follows it — back, and say why.
      ref.read(pendingFollow.notifier).state = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'خطا در عملیات'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // The signed-in user's own following count changed too.
      final me = ref.read(currentUserProvider).valueOrNull?.id ??
          ref.read(authRepositoryProvider).currentUserOrNull?.id;
      if (me != null) ref.invalidate(publicProfileProvider(me));

      if (widget.routeUserId != widget.profile.userId) {
        ref.invalidate(publicProfileProvider(widget.routeUserId));
      }
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing =
        ref.watch(pendingFollowProvider(widget.profile.userId)) ??
            widget.profile.isFollowing;

    return SizedBox(
      width: 200,
      child: isFollowing
          ? OutlinedButton.icon(
              onPressed: _toggle,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('دنبال می‌کنید'),
            )
          : FilledButton.icon(
              onPressed: _toggle,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('دنبال کردن'),
            ),
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
              // Follow is applied optimistically, so this count has to move
              // with the button rather than wait for the round trip. The
              // adjustment cancels itself out as soon as the refreshed
              // profile catches up.
              value: () {
                final pending =
                    ref.watch(pendingFollowProvider(profile.userId));
                final delta = pending == null || pending == profile.isFollowing
                    ? 0
                    : (pending ? 1 : -1);
                return (profile.followersCount + delta)
                    .clamp(0, 1 << 31)
                    .toPersian;
              }(),
              onTap: () => context.push('/user/${profile.userId}/followers'),
            ),
            _StatColumn(
              label: 'دنبال‌شده‌ها',
              value: profile.followingCount.toPersian,
              onTap: () => context.push('/user/${profile.userId}/following'),
            ),
            _StatColumn(
              // Films *and* series — the profile headline does not split them.
              label: 'فیلم و سریال\nدیده‌شده',
              value: profile.totalWatched.toPersian,
              onTap: () => context.push('/user/${profile.userId}/watched'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Follow / Unfollow Button
        if (!isOwnProfile)
          Center(
            child: _FollowButton(
              profile: profile,
              routeUserId: routeUserId,
            ),
          ),
        const Divider(height: AppSpacing.xxl),

        // ── 3. Favourite genres, and the way into the diary ───────────
        // IntrinsicHeight, not `CrossAxisAlignment.stretch`: this Row sits in
        // a ListView, so its own height is unbounded, and stretching children
        // into that hands them an infinite height and fails the layout.
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.category_outlined,
                label: 'ژانرهای موردعلاقه',
                value: profile.favoriteGenres.isEmpty
                    ? 'نامشخص'
                    : profile.favoriteGenres.join('، '),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.menu_book_outlined,
                label: 'دفترچه تماشا',
                value: 'مشاهده',
                onTap: () => context.push('/user/${profile.userId}/diary'),
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── 3.1. Favourites ───────────────────────────────────────────
        _PosterRail(
          title: 'موردعلاقه‌ها',
          emptyMessage: 'هنوز اثری به موردعلاقه‌ها افزوده نشده است.',
          activities: ref.watch(userFavouritesProvider(profile.userId)),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── 3.5. Recent activity ─────────────────────────────────────
        _PosterRail(
          title: 'فعالیت‌های اخیر',
          emptyMessage: 'هنوز فیلم یا سریالی ثبت نشده است.',
          activities: ref.watch(userRecentTitlesProvider(profile.userId)),
        ),
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

/// A titled horizontal strip of posters, used for the favourites and
/// recent-activity sections.
class _PosterRail extends StatelessWidget {
  const _PosterRail({
    required this.title,
    required this.emptyMessage,
    required this.activities,
  });

  final String title;
  final String emptyMessage;
  final AsyncValue<List<SocialActivity>> activities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (activities) {
          AsyncData(:final value) when value.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              emptyMessage,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          AsyncData(:final value) => SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: value.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  ActivityPoster(activity: value[index], width: 86),
            ),
          ),
          AsyncError() => Text(
            'خطا در بارگذاری',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          _ => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;

  /// Every counter on this row stands for a list; tapping opens it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
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
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// When set the whole card is tappable — used by the diary card, which is
  /// a door rather than a statistic.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
            if (onTap != null)
              Icon(
                Icons.chevron_left,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
        ),
      ),
    );
  }
}
