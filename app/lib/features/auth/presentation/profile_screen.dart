import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../router/app_router.dart';
import '../../social/presentation/social_providers.dart';
import '../../tracking/presentation/tracking_providers.dart';
import 'auth_providers.dart';

/// FR-04 §5.4 — profile, and the entry point to FR-19 statistics.
///
/// A guest sees the sign-in prompt instead: §4.1 makes registration mandatory
/// for recording activity, ratings, reviews, and personal lists.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(currentUserProvider).valueOrNull ??
        ref.watch(authRepositoryProvider).currentUserOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navProfile)),
      body: user == null ? const _GuestPrompt() : _Profile(user: user),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.person_outline,
      message:
          'برای ثبت فعالیت، امتیاز، نظر و فهرست شخصی\n'
          'وارد حساب کاربری خود شوید',
      action: Column(
        children: [
          FilledButton(
            onPressed: () => context.push(AppRoutes.login),
            child: const Text('ورود'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(AppRoutes.register),
            child: const Text('ساخت حساب کاربری'),
          ),
        ],
      ),
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              UserAvatar(
                path: (user.avatarPath != null &&
                        user.avatarPath!.trim().isNotEmpty &&
                        user.avatarPath!.trim() != 'null')
                    ? user.avatarPath!.trim()
                    : null,
                initial: user.firstName.trim().isNotEmpty
                    ? user.firstName.trim().characters.first
                    : (user.displayName.trim().isNotEmpty
                        ? user.displayName.trim().characters.first
                        : '؟'),
                radius: 36,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: theme.textTheme.titleLarge),
                    Text(
                      '@${user.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(user.bio!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // FR-01 — the three counters every profile carries automatically.
        const _ProfileCounters(),
        const Divider(height: AppSpacing.xxl),

        ListTile(
          leading: const Icon(Icons.public_rounded),
          title: const Text('پروفایل عمومی من'),
          subtitle: Text('شناسه: ${user.id} (@${user.username})'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push('/user/${user.id}'),
        ),
        ListTile(
          leading: const Icon(Icons.person_search_rounded),
          title: const Text('یافتن و دنبال کردن کاربران'),
          subtitle: const Text('مشاهده پروفایل و فهرست‌ها با شناسه یا نام کاربری'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _findUserDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.dynamic_feed_rounded),
          title: const Text('فعالیت‌های دوستان (Activity Feed)'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push(AppRoutes.activityFeed),
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart_rounded),
          title: const Text('آمار فعالیت من'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push(AppRoutes.statistics),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('ویرایش پروفایل'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _editProfile(context, ref),
        ),
        const _BiometricToggle(),
        ListTile(
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text('خروج', style: TextStyle(color: theme.colorScheme.error)),
          onTap: () async {
            await ref.read(authRepositoryProvider).logout();
          },
        ),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppStrings.tmdbAttribution,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final firstName = TextEditingController(text: user.firstName);
    final lastName = TextEditingController(text: user.lastName);
    final username = TextEditingController(text: user.username);
    final bio = TextEditingController(text: user.bio ?? '');
    var avatarPath = user.avatarPath;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ویرایش پروفایل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarPicker(
                  path: avatarPath,
                  initial: user.firstName.characters.take(1).toString(),
                  radius: 36,
                  onChanged: (path) => setState(() => avatarPath = path),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: firstName,
                  decoration: const InputDecoration(labelText: 'نام'),
                ),
                TextField(
                  controller: lastName,
                  decoration: const InputDecoration(labelText: 'نام خانوادگی'),
                ),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'نام کاربری'),
                ),
                TextField(
                  controller: bio,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'توضیحات کوتاه'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          firstName: firstName.text,
          lastName: lastName.text,
          username: username.text,
          bio: bio.text,
          avatarPath: avatarPath,
          clearAvatar: avatarPath == null && user.avatarPath != null,
        );

    final failure = result.failureOrNull;
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  void _findUserDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => const _FindUsersSheet(),
    );
  }
}


/// The three FR-01 counters, read live.
///
/// They used to come from the cached [AppUser], which is built once at
/// sign-in — so watching a film left them showing zero until the next login.
/// Deriving them here means they follow the data.
class _ProfileCounters extends ConsumerWidget {
  const _ProfileCounters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counters = ref.watch(profileCountersProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Counter(label: 'فیلم‌های\nدیده‌شده', value: counters?.moviesWatched),
          _Counter(
            label: 'سریال‌های\nدنبال‌شده',
            value: counters?.seriesFollowed,
          ),
          _Counter(label: 'موردعلاقه‌ها', value: counters?.favourites),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value});

  final String label;

  /// Null while the counts are still loading — shown as a dash rather than a
  /// misleading zero.
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            value?.toPersian ?? '—',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            // Two short lines rather than one long one: «سریال‌های دنبال‌شده»
            // does not fit a third of a phone's width and was colliding with
            // its neighbours.
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// FR-02's biometric clause: "unless the user requests that biometric login be
/// enabled for them".
class _BiometricToggle extends ConsumerStatefulWidget {
  const _BiometricToggle();

  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(authRepositoryProvider).isBiometricEnabled;

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('ورود با اثر انگشت'),
      subtitle: const Text(
        'در صورت فعال بودن، هنگام باز کردن برنامه پرسیده می‌شود',
      ),
      value: enabled,
      onChanged: (value) async {
        // Captured before the await: after it, `context` may be gone.
        final messenger = ScaffoldMessenger.of(context);

        final result = await ref
            .read(authRepositoryProvider)
            .setBiometricEnabled(enabled: value);

        if (!mounted) return;
        final failure = result.failureOrNull;
        if (failure != null) {
          messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        }
        setState(() {});
      },
    );
  }
}

class _FindUsersSheet extends ConsumerStatefulWidget {
  const _FindUsersSheet();

  @override
  ConsumerState<_FindUsersSheet> createState() => _FindUsersSheetState();
}

class _FindUsersSheetState extends ConsumerState<_FindUsersSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(userSearchProvider(_query));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'یافتن و دنبال کردن کاربران',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'جستجوی نام کاربری یا شناسه کاربر...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _query = val.trim()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: switch (usersAsync) {
                  AsyncData(:final value) =>
                    value.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_outlined,
                                    size: 48,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    _query.isEmpty
                                        ? 'هیچ کاربری در سیستم ثبت نشده است'
                                        : 'کاربری با عنوان «$_query» یافت نشد',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (_query.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        unawaited(
                                          context.push('/user/$_query'),
                                        );
                                      },
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('بررسی مستقیم شناسه'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            itemCount: value.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final profile = value[index];
                              return ListTile(
                                leading: UserAvatar(
                                  path: (profile.avatarUrl != null &&
                                          profile.avatarUrl!.trim().isNotEmpty &&
                                          profile.avatarUrl!.trim() != 'null')
                                      ? profile.avatarUrl!.trim()
                                      : null,
                                  initial: profile.username.trim().isNotEmpty
                                      ? profile.username.trim().characters.first
                                      : '؟',
                                  radius: 20,
                                ),
                                title: Text(
                                  profile.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  profile.bio ??
                                      '${profile.totalWatched.toPersian} فیلم دیده',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () {
                                  Navigator.pop(context);
                                  unawaited(
                                    context.push('/user/${profile.userId}'),
                                  );
                                },
                              );
                            },
                          ),
                  AsyncError(:final error) => Center(
                      child: Text(
                        error.toString(),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  _ => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

