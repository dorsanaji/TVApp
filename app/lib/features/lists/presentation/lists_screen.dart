import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../../domain/entities/social/custom_list.dart';
import '../../../domain/repositories/list_repository.dart';
import '../../../router/app_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../social/presentation/social_providers.dart';
import 'add_to_list_sheet.dart';
import 'list_providers.dart';

/// FR-17 §5.17 & Social: Personal lists & Collaborative shared lists.
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.navLists)),
        body: const SignInRequired(
          message: 'برای ساختن و مدیریت فهرست‌ها\nوارد حساب خود شوید',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.navLists),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.bookmark_outline),
                text: 'فهرست‌های شخصی',
              ),
              Tab(
                icon: Icon(Icons.group_outlined),
                text: 'فهرست‌های اشتراکی',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PersonalListsTab(),
            _CollaborativeListsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Personal Lists ───────────────────────────────────────────────────

class _PersonalListsTab extends ConsumerWidget {
  const _PersonalListsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalListsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('فهرست شخصی جدید'),
      ),
      body: switch (async) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const EmptyState(
                  message: AppStrings.emptyLists,
                  icon: Icons.playlist_add,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88, top: AppSpacing.sm),
                  itemCount: value.length,
                  itemBuilder: (context, index) =>
                      _ListTile(list: value[index]),
                ),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(personalListsProvider),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await promptForListName(context);
    if (name == null || !context.mounted) return;

    final result = await ref.read(listActionsProvider).create(name);
    final failure = result.failureOrNull;
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _ListTile extends ConsumerWidget {
  const _ListTile({required this.list});

  final PersonalList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawCover = list.coverPath;
    final cleanCover = (rawCover != null &&
            rawCover.trim().isNotEmpty &&
            rawCover.trim() != 'null')
        ? rawCover.trim()
        : null;
    final cover = cleanCover != null ? Env.imageUrl(cleanCover) : null;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: SizedBox(
          width: 44,
          height: 66,
          child: (cover != null &&
                  cover.trim().isNotEmpty &&
                  cover.trim() != 'null')
              ? CachedNetworkImage(
                  imageUrl: cover.trim(),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.playlist_play),
                  ),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.playlist_play),
                  ),
                )
              : ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.playlist_play),
                ),
        ),
      ),
      title: Text(list.name),
      subtitle: Text('${list.itemCount.toPersian} اثر'),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'rename' => _rename(context, ref),
          'delete' => _delete(context, ref),
          _ => null,
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'rename', child: Text(AppStrings.edit)),
          PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _ListDetailScreen(list: list)),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await promptForListName(
      context,
      initialValue: list.name,
      title: 'تغییر نام فهرست',
    );
    if (name == null) return;
    await ref.read(listActionsProvider).rename(list.id, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف «${list.name}»؟'),
        content: const Text('این فهرست و محتوای آن حذف می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(listActionsProvider).delete(list.id);
    }
  }
}

/// The contents of one personal list.
class _ListDetailScreen extends ConsumerWidget {
  const _ListDetailScreen({required this.list});

  final PersonalList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listItemsProvider(list.id));

    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: switch (async) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const EmptyState(
                  message: 'این فهرست هنوز خالی است',
                  icon: Icons.playlist_add,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.5,
                  ),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final item = value[index];
                    return GestureDetector(
                      onLongPress: () => ref
                          .read(listActionsProvider)
                          .remove(list.id, item.id, item.type),
                      child: PosterCard(
                        item: item,
                        width: double.infinity,
                        onTap: () => context.goToDetail(item),
                      ),
                    );
                  },
                ),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(listItemsProvider(list.id)),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }
}

// ── Tab 2: Collaborative Lists ──────────────────────────────────────────────

class _CollaborativeListsTab extends ConsumerWidget {
  const _CollaborativeListsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCollaborativeListsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCollaborative(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('فهرست اشتراکی جدید'),
      ),
      body: switch (async) {
        AsyncData(:final value) =>
          value.isEmpty
              ? EmptyState(
                  message:
                      'شما هنوز در فهرست اشتراکی عضو نیستید\nیک فهرست مشترک بسازید و با دوستان خود فیلم انتخاب کنید!',
                  icon: Icons.group_work_outlined,
                  action: FilledButton.icon(
                    onPressed: () => _createCollaborative(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('ساخت اولین فهرست اشتراکی'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88, top: AppSpacing.sm),
                  itemCount: value.length,
                  itemBuilder: (context, index) =>
                      _CollaborativeListTile(list: value[index]),
                ),
        AsyncError(:final error) => ErrorView(
          failure: error is Failure ? error : const FetchFailure(),
          onRetry: () => ref.invalidate(myCollaborativeListsProvider),
        ),
        _ => LoadingShimmer.listRows(),
      },
    );
  }

  Future<void> _createCollaborative(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isPublic = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ساخت فهرست اشتراکی جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'عنوان فهرست *',
                    hintText: 'مثلاً: فیلم‌های آخر هفته با بچه‌ها',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (اختیاری)',
                    hintText: 'توضیح کوتاه درباره این فهرست...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فهرست عمومی'),
                  subtitle: const Text(
                    'سایر کاربران می‌توانند این فهرست را در پروفایل شما ببینند',
                  ),
                  value: isPublic,
                  onChanged: (val) => setState(() => isPublic = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogCtx, true);
                }
              },
              child: const Text('ایجاد'),
            ),
          ],
        ),
      ),
    );

    if (created == true && context.mounted) {
      final title = titleController.text.trim();
      final desc =
          descController.text.trim().isEmpty ? null : descController.text.trim();
      final res = await ref.read(socialActionsProvider).createList(
        title: title,
        description: desc,
        isPublic: isPublic,
      );

      if (context.mounted) {
        switch (res) {
          case Ok(:final value):
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فهرست اشتراکی با موفقیت ساخته شد')),
            );
            unawaited(context.push('/collaborative-list/${value.listId}'));
          case Err(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
        }
      }
    }
  }
}

class _CollaborativeListTile extends ConsumerWidget {
  const _CollaborativeListTile({required this.list});

  final CustomList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final isOwner = currentUserId != null && list.isOwner(currentUserId);
    final rawCover = list.coverPath;
    final cleanCover = (rawCover != null &&
            rawCover.trim().isNotEmpty &&
            rawCover.trim() != 'null')
        ? rawCover.trim()
        : null;
    final cover = cleanCover != null ? Env.imageUrl(cleanCover) : null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            width: 48,
            height: 64,
            child: (cover != null &&
                    cover.trim().isNotEmpty &&
                    cover.trim() != 'null')
                ? CachedNetworkImage(
                    imageUrl: cover.trim(),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.group_outlined),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.group_work_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                list.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOwner)
              Container(
                margin: const EdgeInsetsDirectional.only(start: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'سازنده',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            () {
              final desc = list.description?.trim();
              if (desc != null && desc.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }(),
            Row(
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${list.itemCount.toPersian} اثر',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${list.collaboratorCount.toPersian} عضو',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: isOwner
            ? PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') {
                    unawaited(_deleteCollaborativeList(context, ref, list));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('حذف فهرست', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : const Icon(Icons.chevron_left),
        onTap: () => unawaited(context.push('/collaborative-list/${list.listId}')),
      ),
    );
  }

  Future<void> _deleteCollaborativeList(
    BuildContext context,
    WidgetRef ref,
    CustomList list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف «${list.title}»؟'),
        content: const Text(
          'این فهرست اشتراکی و تمام اطلاعات آن حذف خواهد شد و اعضا دیگر به آن دسترسی نخواهند داشت.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final res = await ref.read(socialActionsProvider).deleteList(list.listId);
      if (context.mounted) {
        switch (res) {
          case Ok():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فهرست حذف شد')),
            );
          case Err(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
        }
      }
    }
  }
}
