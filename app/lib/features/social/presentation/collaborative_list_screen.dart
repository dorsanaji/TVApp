import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/poster_card.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/social/collaboration_request.dart';
import '../../../domain/entities/social/custom_list.dart';
import '../../../domain/entities/social/custom_list_item.dart';
import '../../../domain/entities/social/list_collaborator.dart';
import '../../../domain/entities/social/list_invite_code.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../router/app_router.dart';
import 'social_providers.dart';

/// Task 3.2: CollaborativeListScreen.
///
/// Detail screen for a CustomList supporting multi-user collaboration.
/// Features:
///  * Real-time stream updates for list details, items, and collaborators
///  * Add/manage collaborators with user search & suggestions
///  * Join public collaborative lists directly
///  * FloatingActionButton for collaborators to search & add titles via TMDB
class CollaborativeListScreen extends ConsumerWidget {
  const CollaborativeListScreen({required this.listId, super.key});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(collaborativeListStreamProvider(listId));
    final listDetailsAsync = ref.watch(collaborativeListDetailsProvider(listId));
    final itemsAsync = ref.watch(collaborativeListItemsStreamProvider(listId));
    final collabsAsync = ref.watch(listCollaboratorsStreamProvider(listId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull ??
        ref.watch(authRepositoryProvider).currentUserOrNull;
    final currentUserId = currentUser?.id;
    final isCollabAsync = ref.watch(isCollaboratorProvider(listId));

    final list = listAsync.valueOrNull ?? listDetailsAsync.valueOrNull;
    final collabs = collabsAsync.valueOrNull ?? const [];
    final isOwner =
        list != null && currentUserId != null && list.isOwner(currentUserId);
    final isCollaborator = isOwner ||
        (currentUserId != null && collabs.any((c) => c.userId == currentUserId)) ||
        (isCollabAsync.valueOrNull ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.title ?? 'فهرست مشترک'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.manage_accounts_outlined),
              tooltip: 'مدیریت همکاران',
              onPressed: () => _openCollaboratorsSheet(
                context,
                ref,
                isOwner: isOwner,
              ),
            ),
          // Joining is a request the owner accepts, so leaving has to be the
          // collaborator's own to make — otherwise the only way out is asking
          // the owner to remove you.
          if (!isOwner && isCollaborator && currentUserId != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'خروج از فهرست',
              onPressed: () => _confirmLeave(context, ref, currentUserId),
            ),
        ],
      ),
      body: list != null
          ? _CollaborativeListBody(
              list: list,
              itemsAsync: itemsAsync,
              collabsAsync: collabsAsync,
              isCollaborator: isCollaborator,
              isOwner: isOwner,
            )
          : switch (listDetailsAsync) {
              AsyncData(:final value) => _CollaborativeListBody(
                  list: value,
                  itemsAsync: itemsAsync,
                  collabsAsync: collabsAsync,
                  isCollaborator: isCollaborator,
                  isOwner: isOwner,
                ),
              AsyncError(:final error) => ErrorView(
                  failure: error is Failure
                      ? error
                      : ErrorMapper.fromUnknown(error),
                  onRetry: () {
                    ref.invalidate(collaborativeListStreamProvider(listId));
                    ref.invalidate(collaborativeListDetailsProvider(listId));
                    ref.invalidate(collaborativeListItemsStreamProvider(listId));
                    ref.invalidate(collaborativeListItemsProvider(listId));
                    ref.invalidate(listCollaboratorsStreamProvider(listId));
                    ref.invalidate(listCollaboratorsProvider(listId));
                    ref.invalidate(collaborationRequestsStreamProvider(listId));
                    ref.invalidate(collaborationRequestsProvider(listId));
                  },
                ),
              _ => LoadingShimmer.listRows(),
            },
    );
  }

  void _openCollaboratorsSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isOwner,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ManageCollaboratorsSheet(
        listId: listId,
        isOwner: isOwner,
      ),
    );
  }

  /// Leaves the list, giving up edit access but leaving the list itself — and
  /// anything already added to it — untouched.
  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('خروج از فهرست'),
        content: const Text(
          'دسترسی شما برای افزودن و حذف آثار در این فهرست برداشته می‌شود. '
          'آثاری که پیش‌تر اضافه کرده‌اید در فهرست باقی می‌مانند. '
          'برای بازگشت باید دوباره درخواست دسترسی بدهید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final res = await ref.read(socialActionsProvider).removeCollaborator(
          listId: listId,
          userId: currentUserId,
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.isOk
              ? 'از فهرست خارج شدید.'
              : (res.failureOrNull?.message ?? 'خطا در خروج از فهرست'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // The list is no longer one of theirs, so drop back rather than leave them
    // on a page they can no longer edit.
    if (res.isOk && context.mounted) context.pop();
  }
}

/// The invitation code for a private list, with a copy button.
///
/// Shown only to the owner of a private list: a private list appears on
/// nobody's profile and in no browse screen, so handing out this code is the
/// only way anyone else can reach it. The same code works for as many people
/// as it is given to.
class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = ListInviteCode.forList(listId);
    if (code == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'کد دعوت این فهرست خصوصی',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'رونوشت کد',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('کد دعوت رونوشت شد.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'این کد را برای هرکس که می‌خواهید بفرستید؛ با وارد کردن آن در بخش '
            '«پیوستن با کد دعوت» به این فهرست اضافه می‌شود. فهرست خصوصی در '
            'پروفایل عمومی هیچ‌کدامتان دیده نمی‌شود.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollaborativeListBody extends ConsumerWidget {
  const _CollaborativeListBody({
    required this.list,
    required this.itemsAsync,
    required this.collabsAsync,
    required this.isCollaborator,
    this.isOwner = false,
  });

  final CustomList list;
  final AsyncValue<List<CustomListItem>> itemsAsync;
  final AsyncValue<List<ListCollaborator>> collabsAsync;
  final bool isCollaborator;
  final bool isOwner;

  Future<void> _requestAccess(BuildContext context, WidgetRef ref) async {
    final currentUserId = ref.read(currentUserProvider).valueOrNull?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'برای ارسال درخواست دسترسی لطفاً ابتدا وارد حساب کاربری خود شوید.',
          ),
          action: SnackBarAction(
            label: 'ورود',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    // Flip the banner now; the write and its re-read take several round trips.
    final pending = pendingAccessRequestProvider(list.listId);
    ref.read(pending.notifier).state = true;

    final res = await ref.read(socialActionsProvider).requestCollaboratorAccess(
          listId: list.listId,
        );

    if (res.isErr) ref.read(pending.notifier).state = null;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.isOk
                ? 'درخواست دسترسی شما برای سازنده فهرست ارسال شد.'
                : (res.failureOrNull?.message ?? 'خطا در ارسال درخواست دسترسی'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final pending = pendingAccessRequestProvider(list.listId);
    ref.read(pending.notifier).state = false;

    final res = await ref.read(socialActionsProvider).cancelCollaboratorRequest(
          listId: list.listId,
        );

    if (res.isErr) ref.read(pending.notifier).state = null;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.isOk
                ? 'درخواست دسترسی لغو شد.'
                : (res.failureOrNull?.message ?? 'خطا در لغو درخواست'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _acceptRequest(
    BuildContext context,
    WidgetRef ref, {
    required String requesterId,
    required String username,
  }) async {
    final res = await ref.read(socialActionsProvider).acceptCollaboratorRequest(
          listId: list.listId,
          userId: requesterId,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.isOk
                ? 'دسترسی ویرایش به «$username» داده شد.'
                : (res.failureOrNull?.message ?? 'خطا در تأیید درخواست'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref, {
    required String requesterId,
    required String username,
  }) async {
    final res = await ref.read(socialActionsProvider).rejectCollaboratorRequest(
          listId: list.listId,
          userId: requesterId,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.isOk
                ? 'درخواست «$username» رد شد.'
                : (res.failureOrNull?.message ?? 'خطا در رد درخواست'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCollaboratorsSheet(
    BuildContext context,
    WidgetRef ref, {
    required String listId,
    required bool isOwner,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ManageCollaboratorsSheet(
        listId: listId,
        isOwner: isOwner,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // One source per thing. `watchList`, `watchListItems`,
    // `watchCollaborators` and `watchCollaborationRequests` each perform a
    // direct read and yield it before subscribing, so also watching the
    // matching one-shot provider issued every query twice on open — which is
    // most of what the loading wait was.
    final items = itemsAsync.valueOrNull ?? const <CustomListItem>[];
    final collabs = collabsAsync.valueOrNull ?? const <ListCollaborator>[];
    final requests =
        ref.watch(collaborationRequestsStreamProvider(list.listId)).valueOrNull ??
            const <CollaborationRequest>[];

    final hasPending = ref.watch(hasPendingRequestProvider(list.listId));

    final rawCover = list.coverPath;
    final cleanCover = (rawCover != null &&
            rawCover.trim().isNotEmpty &&
            rawCover.trim() != 'null')
        ? rawCover.trim()
        : null;
    final coverUrl = cleanCover != null ? Env.imageUrl(cleanCover) : null;

    return CustomScrollView(
      slivers: [
        // ── 1. List Header & Description ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coverUrl != null &&
                    coverUrl.trim().isNotEmpty &&
                    coverUrl.trim() != 'null') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: SizedBox(
                      width: double.infinity,
                      height: 140,
                      child: CachedNetworkImage(
                        imageUrl: coverUrl.trim(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.playlist_play, size: 40),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.playlist_play, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        list.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: list.isPublic
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        list.isPublic ? 'عمومی' : 'خصوصی',
                        style: TextStyle(
                          color: list.isPublic ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                () {
                  final desc = list.description?.trim();
                  if (desc != null && desc.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        desc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }(),
                const SizedBox(height: AppSpacing.md),

                // ── Invitation code, for a private list's owner ───────
                if (isOwner && !list.isPublic)
                  _InviteCodeCard(listId: list.listId),

                // ── Owner Pending Collaborator Requests Card ──────────
                if (isOwner && requests.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mark_email_unread_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'درخواست‌های دسترسی به فهرست (${requests.length.toPersian}):',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...requests.map((req) {
                          final rawName = req.username.trim();
                          final username =
                              rawName.isNotEmpty ? rawName : 'کاربر';
                          final rawAvatar = req.avatarUrl?.trim();
                          final avatarUrl = (rawAvatar != null &&
                                  rawAvatar.isNotEmpty &&
                                  rawAvatar != 'null')
                              ? rawAvatar
                              : null;
                          final requesterId = req.userId.trim();
                          final initial = username.isNotEmpty
                              ? username.characters.first
                              : '؟';

                          return Padding(
                            key: ValueKey(req.requestId),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      UserAvatar(
                                        path: avatarUrl,
                                        initial: initial,
                                        radius: 16,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'درخواست مشارکت در افزودن و حذف آثار',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm),
                                          ),
                                          onPressed: () => _rejectRequest(
                                            context,
                                            ref,
                                            requesterId: requesterId,
                                            username: username,
                                          ),
                                          child: const Text(
                                            'رد',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            // The app theme gives every filled
                                            // button `Size.fromHeight(48)`,
                                            // whose width is `double.infinity`.
                                            // That is harmless inside a Column,
                                            // but a Row hands non-flexible
                                            // children an unbounded main axis,
                                            // so the button would be asked to
                                            // lay out at an infinite width and
                                            // the whole card would fail to lay
                                            // out — leaving the owner staring
                                            // at an empty screen.
                                            //
                                            // Height 40 matches the Material
                                            // default the sibling
                                            // OutlinedButton uses, so the two
                                            // still line up.
                                            minimumSize: const Size(0, 40),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md),
                                          ),
                                          onPressed: () => _acceptRequest(
                                            context,
                                            ref,
                                            requesterId: requesterId,
                                            username: username,
                                          ),
                                          child: const Text(
                                            'تأیید دسترسی',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                // ── Collaborators Rail ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'همکاران فهرست (${collabs.length.toPersian}):',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOwner)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _openCollaboratorsSheet(
                          context,
                          ref,
                          listId: list.listId,
                          isOwner: isOwner,
                        ),
                        icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                        label: const Text('مدیریت'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (collabs.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: collabs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final c = collabs[index];
                        final rawAvatar = c.avatarUrl?.trim();
                        final cleanAvatar = (rawAvatar != null &&
                                rawAvatar.isNotEmpty &&
                                rawAvatar != 'null')
                            ? rawAvatar
                            : null;
                        final uname = c.username?.trim();
                        final uid = c.userId.trim();
                        final displayName = (uname != null && uname.isNotEmpty)
                            ? uname
                            : (uid.isNotEmpty ? uid : 'کاربر');
                        final initialChar = displayName.isNotEmpty
                            ? displayName.characters.first
                            : '؟';
                        return ActionChip(
                          avatar: UserAvatar(
                            path: cleanAvatar,
                            initial: initialChar,
                            radius: 12,
                          ),
                          label: Text(displayName),
                          onPressed: () => context.push('/user/${c.userId}'),
                        );
                      },
                    ),
                  ),

                // ── Access Request Banner for Non-Collaborators ───────
                if (!isCollaborator) ...[
                  const SizedBox(height: AppSpacing.md),
                  if (hasPending)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.pending_actions_outlined,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'درخواست در انتظار تأیید مالک',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEF6C00),
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: const Color(0xFFEF6C00),
                                  side: const BorderSide(
                                      color: Color(0xFFFFB74D)),
                                ),
                                onPressed: () => _cancelRequest(context, ref),
                                child: const Text('لغو درخواست'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'درخواست دسترسی شما برای سازنده این فهرست ارسال شده است. پس از تأیید، امکان افزودن یا حذف آثار برای شما فعال خواهد شد.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.25),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'درخواست دسترسی ویرایش فهرست',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'در این فهرست تنها سازنده و همکاران تأییدشده می‌توانند آثار را اضافه یا حذف کنند. برای مشارکت در ویرایش، درخواست دسترسی دهید.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _requestAccess(context, ref),
                              icon: const Icon(Icons.send_outlined, size: 16),
                              label: const Text('درخواست دسترسی'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const Divider(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // ── 2. Movie/Series Grid ──────────────────────────────────────
        if ((itemsAsync.isLoading ||
                ref
                    .watch(collaborativeListItemsProvider(list.listId))
                    .isLoading) &&
            items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyState(
                    icon: Icons.movie_outlined,
                    message:
                        'هنوز اثری به این فهرست اضافه نشده است.\n'
                        'برای افزودن اثر، به صفحه فیلم یا سریال موردنظر رفته و از دکمه «افزودن به فهرست» آن را به این فهرست مشترک اضافه کنید.',
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.lg,
              bottom: 88,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  final rawPoster = item.posterPath;
                  final cleanPoster = (rawPoster != null &&
                          rawPoster.trim().isNotEmpty &&
                          rawPoster.trim() != 'null')
                      ? rawPoster.trim()
                      : null;
                  final summary = MediaSummary(
                    id: item.mediaId,
                    type: item.mediaType,
                    title: item.title,
                    posterPath: cleanPoster,
                    overview: item.overview,
                    releaseDate: item.releaseDate,
                    voteAverage: item.voteAverage,
                  );

                  return Stack(
                    children: [
                      PosterCard(
                        item: summary,
                        width: double.infinity,
                        onTap: () => context.goToDetail(summary),
                      ),
                      if (isCollaborator)
                        PositionedDirectional(
                          top: 4,
                          end: 4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.7),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => ref
                                  .read(socialActionsProvider)
                                  .removeMovieFromList(
                                    listId: list.listId,
                                    mediaId: item.mediaId,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Search & Add Collaborator Sheet ──────────────────────────────────────
/// Manages who is already on the list.
///
/// Adding a collaborator outright is deliberately not offered: it wrote a row
/// keyed to whatever was typed, so a typo or a username that resolved to a
/// different account silently granted the wrong person edit access. Joining
/// now goes one way — someone asks with the request button or an invitation
/// code, and the owner accepts — which means the person joining is always the
/// person who ends up on the list. The owner can still remove anyone.
class _ManageCollaboratorsSheet extends ConsumerWidget {
  const _ManageCollaboratorsSheet({
    required this.listId,
    required this.isOwner,
  });

  final String listId;
  final bool isOwner;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف همکار'),
        content: Text(
          'دسترسی «$name» برای افزودن و حذف آثار در این فهرست برداشته می‌شود. '
          'آثاری که پیش‌تر اضافه کرده است در فهرست باقی می‌مانند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final res = await ref
        .read(socialActionsProvider)
        .removeCollaborator(listId: listId, userId: userId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.isOk
              ? '«$name» از همکاران فهرست حذف شد'
              : (res.failureOrNull?.message ?? 'خطا در حذف همکار'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collabs =
        ref.watch(listCollaboratorsStreamProvider(listId)).valueOrNull ??
            ref.watch(listCollaboratorsProvider(listId)).valueOrNull ??
            const <ListCollaborator>[];
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
        ref.watch(authRepositoryProvider).currentUserOrNull?.id;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sheetInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'همکاران فهرست (${collabs.length.toPersian})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isOwner
                ? 'برای افزوده شدن، کاربر باید درخواست دسترسی بفرستد یا با کد '
                    'دعوت وارد شود. شما می‌توانید هر همکاری را حذف کنید.'
                : 'تنها سازنده فهرست می‌تواند همکاران را مدیریت کند.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (collabs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'هنوز همکاری به این فهرست اضافه نشده است.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final collaborator in collabs)
                    () {
                      final rawAvatar = collaborator.avatarUrl?.trim();
                      final avatar = (rawAvatar != null &&
                              rawAvatar.isNotEmpty &&
                              rawAvatar != 'null')
                          ? rawAvatar
                          : null;
                      final uname = collaborator.username?.trim();
                      final uid = collaborator.userId.trim();
                      final displayName = (uname != null && uname.isNotEmpty)
                          ? uname
                          : (uid.isNotEmpty ? uid : 'کاربر');
                      final canRemove =
                          isOwner && collaborator.userId != currentUserId;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: UserAvatar(
                          path: avatar,
                          initial: displayName.characters.first,
                          radius: 16,
                        ),
                        title: Text(displayName),
                        trailing: canRemove
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                tooltip: 'حذف همکار',
                                onPressed: () => _remove(
                                  context,
                                  ref,
                                  collaborator.userId,
                                  displayName,
                                ),
                              )
                            : null,
                        onTap: () => context.push('/user/${collaborator.userId}'),
                      );
                    }(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
