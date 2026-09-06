import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../../domain/entities/media_summary.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../social/presentation/social_providers.dart';
import 'list_providers.dart';

/// FR-17 & Social: Add a title to, or remove it from, the user's personal lists
/// AND shared / collaborative watchlists.
///
/// Presented as a dual-tab checklist so that a film or series can be added
/// to multiple personal lists, multiple shared watchlists, or both.
Future<void> showAddToListSheet(BuildContext context, MediaSummary item) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _AddToListSheet(item: item),
  );
}

class _AddToListSheet extends ConsumerWidget {
  const _AddToListSheet({required this.item});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'افزودن به فهرست',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '«${item.title}»',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.bookmark_outline, size: 20),
                    text: 'فهرست‌های شخصی',
                  ),
                  Tab(
                    icon: Icon(Icons.group_outlined, size: 20),
                    text: 'فهرست‌های اشتراکی',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PersonalListsTab(item: item),
                    _CollaborativeListsTab(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: Personal Lists ───────────────────────────────────────────────────

class _PersonalListsTab extends ConsumerWidget {
  const _PersonalListsTab({required this.item});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lists = ref.watch(personalListsProvider).valueOrNull ?? const [];
    final containing =
        ref.watch(listsContainingProvider((id: item.id, type: item.type))).valueOrNull ??
            const <String>{};
    final actions = ref.read(listActionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${lists.length.toPersian} فهرست شخصی',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _createList(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('فهرست شخصی جدید'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (lists.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_border,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(AppStrings.emptyLists),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.tonalIcon(
                      onPressed: () => _createList(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('ساخت اولین فهرست شخصی'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                final isIn = containing.contains(list.id);

                return CheckboxListTile(
                  value: isIn,
                  title: Text(list.name),
                  subtitle: Text('${list.itemCount.toPersian} اثر'),
                  secondary: const Icon(Icons.bookmark_outline),
                  onChanged: (selected) async {
                    if (selected ?? false) {
                      await actions.add(list.id, item);
                    } else {
                      await actions.remove(list.id, item.id, item.type);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final name = await promptForListName(context);
    if (name == null) return;

    final result = await ref.read(listActionsProvider).create(name);
    if (!context.mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return;
    }

    final created = result.valueOrNull;
    if (created != null) {
      await ref.read(listActionsProvider).add(created.id, item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${item.title}» به «$name» اضافه شد'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Tab 2: Shared & Collaborative Lists ─────────────────────────────────────

class _CollaborativeListsTab extends ConsumerStatefulWidget {
  const _CollaborativeListsTab({required this.item});

  final MediaSummary item;

  @override
  ConsumerState<_CollaborativeListsTab> createState() =>
      _CollaborativeListsTabState();
}

class _CollaborativeListsTabState extends ConsumerState<_CollaborativeListsTab> {
  final _inFlight = <String>{};
  final _optimisticState = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_work_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'برای استفاده از فهرست‌های اشتراکی و گروهی، وارد حساب کاربری خود شوید.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => showSignInPrompt(
                  context,
                  action: 'استفاده از فهرست‌های اشتراکی',
                ),
                child: const Text('ورود به حساب کاربری'),
              ),
            ],
          ),
        ),
      );
    }

    final listsAsync = ref.watch(allAvailableCollaborativeListsProvider);
    final myLists =
        ref.watch(myCollaborativeListsProvider).valueOrNull ?? const [];
    final myEditableListIds = myLists.map((l) => l.listId).toSet();
    final containingAsync = ref.watch(
      collaborativeListsContainingProvider((id: widget.item.id, type: widget.item.type)),
    );
    final containing = containingAsync.valueOrNull ?? const <String>{};
    final currentUser = ref.watch(currentUserProvider).valueOrNull ??
        ref.watch(authRepositoryProvider).currentUserOrNull;
    final currentUserId = currentUser?.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${(listsAsync.valueOrNull?.length ?? 0).toPersian} فهرست اشتراکی',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _createCollaborativeList(context, ref),
                icon: const Icon(Icons.group_add_outlined, size: 18),
                label: const Text('فهرست اشتراکی جدید'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (listsAsync) {
            AsyncData(:final value) when value.isEmpty => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'شما هنوز در هیچ فهرست اشتراکی عضو نیستید.\nیک فهرست گروهی جدید بسازید و با دوستان خود فیلم به اشتراک بگذارید!',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.tonalIcon(
                        onPressed: () => _createCollaborativeList(context, ref),
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('ساخت اولین فهرست اشتراکی'),
                      ),
                    ],
                  ),
                ),
              ),
            AsyncData(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final list = value[index];
                  final isIn = _optimisticState[list.listId] ??
                      containing.contains(list.listId);
                  final isOwner =
                      currentUserId != null && list.isOwner(currentUserId);
                  final isCollaborator = myEditableListIds.contains(list.listId);
                  final canEdit = isOwner || isCollaborator;
                  final isProcessing = _inFlight.contains(list.listId);

                  return CheckboxListTile(
                    value: isIn,
                    title: Row(
                      children: [
                        if (!canEdit) ...[
                          const Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            list.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: list.isPublic
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            list.isPublic ? 'عمومی' : 'خصوصی',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: list.isPublic
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      canEdit
                          ? '${list.itemCount.toPersian} اثر${isOwner ? " • ایجاد شده توسط شما" : " • همکار تأییدشده"}'
                          : '${list.itemCount.toPersian} اثر • نیاز به تأیید مالک برای ویرایش',
                    ),
                    secondary: const Icon(Icons.group_outlined),
                    onChanged: !canEdit
                        ? (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تنها مالک و همکاران تأییدشده می‌توانند این فهرست را ویرایش کنند. لطفاً در صفحه فهرست درخواست دسترسی ارسال کنید.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : (selected) async {
                            if (isProcessing) return; // Ignore repeat clicks while request is in flight
                            final willAdd = selected ?? false;

                            setState(() {
                              _inFlight.add(list.listId);
                              _optimisticState[list.listId] = willAdd;
                            });

                      try {
                        if (willAdd) {
                          final res = await ref
                              .read(socialActionsProvider)
                              .addMovieToList(
                                listId: list.listId,
                                item: widget.item,
                              );
                          if (!context.mounted) return;
                          if (res.isErr) {
                            setState(() => _optimisticState[list.listId] = !willAdd);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.failureOrNull?.message ?? 'خطا در افزودن به فهرست'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          final res = await ref
                              .read(socialActionsProvider)
                              .removeMovieFromList(
                                listId: list.listId,
                                mediaId: widget.item.id,
                                mediaType: widget.item.type,
                              );
                          if (!context.mounted) return;
                          if (res.isErr) {
                            setState(() => _optimisticState[list.listId] = !willAdd);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.failureOrNull?.message ?? 'خطا در حذف از فهرست'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _inFlight.remove(list.listId);
                            _optimisticState.remove(list.listId);
                          });
                        }
                      }
                    },
                  );
                },
              ),
            AsyncError(:final error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('خطا در دریافت فهرست‌های اشتراکی: $error'),
                ),
              ),
            _ => LoadingShimmer.listRows(),
          },
        ),
      ],
    );
  }

  Future<void> _createCollaborativeList(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isPublic = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          title: const Text('فهرست اشتراکی جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'نام فهرست *',
                    hintText: 'مثلاً: فیلم‌های آخر هفته با دوستان',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (اختیاری)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فهرست عمومی'),
                  subtitle: const Text('امکان پیوستن و افزودن اثر برای سایرین'),
                  value: isPublic,
                  onChanged: (val) => setModalState(() => isPublic = val),
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
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    final title = titleController.text.trim();
    final desc = descController.text.trim();

    final res = await ref.read(socialActionsProvider).createList(
          title: title,
          description: desc.isEmpty ? null : desc,
          isPublic: isPublic,
        );

    if (!context.mounted) return;

    if (res.isOk && res.valueOrNull != null) {
      final newList = res.valueOrNull!;
      // Automatically add this movie to the newly created list
      await ref.read(socialActionsProvider).addMovieToList(
            listId: newList.listId,
            item: widget.item,
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فهرست «$title» ایجاد شد و «${widget.item.title}» به آن افزوده شد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'خطا در ایجاد فهرست اشتراکی'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Shared name prompt, used both here and by the lists screen.
///
/// NFR-10 — the form is validated before it is submitted, so an empty name
/// never reaches the repository.
Future<String?> promptForListName(
  BuildContext context, {
  String? initialValue,
  String title = 'نام فهرست',
}) {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثلاً: بهترین فیلم‌های اکشن',
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'نام فهرست نمی‌تواند خالی باشد'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: const Text(AppStrings.save),
        ),
      ],
    ),
  );
}
