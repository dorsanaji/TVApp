import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/l10n/tmdb_localization.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/avatar_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/entities/social/public_profile.dart';
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
          // The internal `user_…` key means nothing to anyone; the username is
          // the identifier people actually share.
          subtitle: Text('شناسه: @${user.username}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push('/user/${user.id}'),
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
        _FavouriteGenresTile(userId: user.id),
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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _EditProfileSheet(user: user),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پروفایل به‌روزرسانی شد.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// FR-04 — editing the account.
///
/// A sheet with a real form rather than the old `AlertDialog`: four bare
/// `TextField`s stacked with no spacing inside a dialog left the filled boxes
/// touching each other, and the dialog's own width squeezed the labels. A
/// widget also means the controllers are disposed at the right time instead
/// of leaking with every open.
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final AppUser user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _username = TextEditingController(text: widget.user.username);
  late final _bio = TextEditingController(text: widget.user.bio ?? '');
  final _formKey = GlobalKey<FormState>();

  late String? _avatarPath = widget.user.avatarPath;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final result = await ref.read(authRepositoryProvider).updateProfile(
          firstName: _firstName.text,
          lastName: _lastName.text,
          username: _username.text,
          bio: _bio.text,
          avatarPath: _avatarPath,
          clearAvatar: _avatarPath == null && widget.user.avatarPath != null,
        );

    if (!mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sheetInset(context),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ویرایش پروفایل',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: AvatarPicker(
                    path: _avatarPath,
                    initial: widget.user.firstName.characters.take(1).toString(),
                    radius: 44,
                    onChanged: (path) => setState(() => _avatarPath = path),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _Field(
                  controller: _firstName,
                  label: 'نام',
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'نام را وارد کنید'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(
                  controller: _lastName,
                  label: 'نام خانوادگی',
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'نام خانوادگی را وارد کنید'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(
                  controller: _username,
                  label: 'شناسه (نام کاربری)',
                  icon: Icons.alternate_email,
                  helper: 'با همین شناسه وارد می‌شوید',
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'شناسه باید حداقل ۳ نویسه باشد'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(
                  controller: _bio,
                  label: 'درباره من',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context, false),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One labelled row of the edit form, so every field is spaced and decorated
/// the same way.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.helper,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? helper;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
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




/// FR-04 — the genres the user says they like, shown on their public profile.
///
/// Kept out of the "edit profile" dialog because it writes somewhere else:
/// names, avatar and bio live in the local account, whereas favourite genres
/// are part of the public profile in Supabase.
class _FavouriteGenresTile extends ConsumerWidget {
  const _FavouriteGenresTile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(userId)).valueOrNull;
    final chosen = profile?.favoriteGenres ?? const <String>[];

    return ListTile(
      leading: const Icon(Icons.category_outlined),
      title: const Text('ژانرهای موردعلاقه'),
      subtitle: Text(
        chosen.isEmpty
            ? 'هنوز ژانری انتخاب نکرده‌اید'
            : chosen.join('، '),
      ),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => _edit(context, ref, chosen),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<String> current,
  ) async {
    final chosen = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _GenrePickerSheet(initial: current),
    );

    if (chosen == null || !context.mounted) return;

    final res = await ref.read(socialActionsProvider).setFavouriteGenres(chosen);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.isOk
              ? 'ژانرهای موردعلاقه ذخیره شد.'
              : (res.failureOrNull?.message ?? 'خطا در ذخیره ژانرها'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _GenrePickerSheet extends StatefulWidget {
  const _GenrePickerSheet({required this.initial});

  final List<String> initial;

  @override
  State<_GenrePickerSheet> createState() => _GenrePickerSheetState();
}

class _GenrePickerSheetState extends State<_GenrePickerSheet> {
  late final Set<String> _selected = widget.initial.toSet();

  static const _max = PublicProfile.maxFavouriteGenres;

  void _toggle(String genre) {
    setState(() {
      if (_selected.contains(genre)) {
        _selected.remove(genre);
      } else if (_selected.length < _max) {
        _selected.add(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = _selected.length >= _max;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ژانرهای موردعلاقه',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length.toPersian} از ${_max.toPersian}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final genre in TmdbLocalization.selectableGenres)
                      FilterChip(
                        label: Text(genre),
                        selected: _selected.contains(genre),
                        // At the cap, only the already-chosen stay tappable,
                        // so the limit is visible rather than a silent no-op.
                        onSelected: full && !_selected.contains(genre)
                            ? null
                            : (_) => _toggle(genre),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, _selected.toList()),
                      child: const Text(AppStrings.save),
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
