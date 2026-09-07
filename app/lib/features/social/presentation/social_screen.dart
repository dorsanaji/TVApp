import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../auth/presentation/auth_providers.dart';
import 'activity_feed_screen.dart';
import 'social_providers.dart';

/// Everything social in one place: what the people you follow are doing, and
/// how to find more of them.
///
/// Both halves used to be buried behind rows on the profile screen, which is
/// where you go to look at yourself — the wrong place to go looking at other
/// people.
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSignedInProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('اجتماعی')),
        body: const SignInRequired(
          message: 'برای دیدن فعالیت دوستان و دنبال کردن کاربران\n'
              'وارد حساب خود شوید',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اجتماعی'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.dynamic_feed_outlined),
                text: 'فعالیت دوستان',
              ),
              Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'کاربران',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ActivityFeedView(),
            FindUsersView(),
          ],
        ),
      ),
    );
  }
}

/// Search for people, and open their profile to follow them.
class FindUsersView extends ConsumerStatefulWidget {
  const FindUsersView({super.key});

  @override
  ConsumerState<FindUsersView> createState() => _FindUsersViewState();
}

class _FindUsersViewState extends ConsumerState<FindUsersView> {
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchController,
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
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: switch (usersAsync) {
            AsyncData(:final value) when value.isEmpty => Center(
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
                        onPressed: () => context.push('/user/$_query'),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('بررسی مستقیم شناسه'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AsyncData(:final value) => ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.bottomInset(context, extra: AppSpacing.lg),
              ),
              itemCount: value.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final profile = value[index];
                final avatar = profile.avatarUrl?.trim();
                final username = profile.username.trim();

                return ListTile(
                  leading: UserAvatar(
                    path: (avatar != null &&
                            avatar.isNotEmpty &&
                            avatar != 'null')
                        ? avatar
                        : null,
                    initial: username.isNotEmpty ? username.characters.first : '؟',
                    radius: 20,
                  ),
                  title: Text(
                    profile.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    profile.bio ??
                        '${profile.totalWatched.toPersian} اثر دیده‌شده',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/user/${profile.userId}'),
                );
              },
            ),
            AsyncError(:final error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}
