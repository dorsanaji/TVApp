import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/bidi_text.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../../domain/entities/media_summary.dart';
import '../../../../domain/repositories/review_repository.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../review_providers.dart';
import 'diary_entry_modal.dart';

/// FR-14 §5.14 and FR-15 §5.15 — reviews, with spoiler handling.
class ReviewSection extends ConsumerWidget {
  const ReviewSection({required this.item, super.key});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final key = (id: item.id, type: item.type);
    final reviews = ref.watch(reviewsProvider(key)).valueOrNull ?? const [];
    final signedIn = ref.watch(isSignedInProvider);
    final currentUserId = ref
        .watch(authRepositoryProvider)
        .currentUserOrNull
        ?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'نظرها',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (signedIn) ...[
                TextButton.icon(
                  onPressed: () => showDiaryEntryModal(context, item: item),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('دفترچه تماشا'),
                ),
                TextButton.icon(
                  onPressed: () => showReviewComposer(context, ref, item),
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('ثبت نظر'),
                ),
              ],
            ],
          ),
          if (!signedIn)
            Text(
              'برای ثبت نظر باید وارد شوید',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if (reviews.isEmpty)
            Text(
              'هنوز نظری ثبت نشده است',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final review in reviews)
            _ReviewTile(
              review: review,
              isMine: review.authorId == currentUserId,
              item: item,
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends ConsumerStatefulWidget {
  const _ReviewTile({
    required this.review,
    required this.isMine,
    required this.item,
  });

  final Review review;
  final bool isMine;
  final MediaSummary item;

  @override
  ConsumerState<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<_ReviewTile> {
  /// FR-15 — spoilers start hidden and are revealed by the user's choice.
  /// Deliberately widget state, not persisted: the acceptance criteria say the
  /// reveal must not survive the session, and it applies to this review alone.
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final review = widget.review;
    final hidden = review.hasSpoiler && !_revealed;

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 3 · تصویر کاربر
                UserAvatar(
                  path: review.authorAvatar,
                  initial: review.authorName.characters.take(1).toString(),
                  radius: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2 · نام کاربر
                      Text(
                        review.authorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // 4 · تاریخ ثبت
                      Text(
                        Formatters.jalaliDate(
                          review.createdAt.toIso8601String(),
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (review.stars != null)
                  Row(
                    children: [
                      Text(
                        '${review.stars}',
                        style: theme.textTheme.labelSmall,
                      ),
                      const Icon(Icons.star_rounded, size: 14),
                    ],
                  ),
                if (widget.isMine)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await showReviewComposer(
                          context,
                          ref,
                          widget.item,
                          existing: review,
                        );
                      } else {
                        await ref
                            .read(reviewRepositoryProvider)
                            .deleteReview(review.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppStrings.edit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.delete),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // 5 · وضعیت اسپویل — masked until revealed.
            if (hidden)
              GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Text(
                          review.body,
                          maxLines: 3,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        'این نظر اسپویل دارد — برای نمایش لمس کنید',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (review.hasSpoiler)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '⚠️ دارای اسپویل',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              // 1 · متن نظر — written by a user, so the language is theirs to
              // choose and the direction follows the text.
              BidiText(review.body, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// The review composer, used for both writing and editing.
///
/// NFR-10 — validated before submission; FR-15 — the spoiler declaration is
/// made here, at the moment of writing, as the brief specifies.
Future<void> showReviewComposer(
  BuildContext context,
  WidgetRef ref,
  MediaSummary item, {
  Review? existing,
}) async {
  final controller = TextEditingController(text: existing?.body ?? '');
  final formKey = GlobalKey<FormState>();
  var hasSpoiler = existing?.hasSpoiler ?? false;

  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      // Symmetric horizontally, so no physical edge is pinned; the bottom
      // inset lifts the sheet clear of the keyboard.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg).copyWith(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'ثبت نظر' : 'ویرایش نظر',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'نظر خود را بنویسید…',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'متن نظر نمی‌تواند خالی باشد'
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('این نظر اسپویل دارد'),
                subtitle: const Text('در ابتدا برای دیگران مخفی خواهد بود'),
                value: hasSpoiler,
                onChanged: (value) => setState(() => hasSpoiler = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(AppStrings.save),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    ),
  );

  if (submitted != true) return;

  final repository = ref.read(reviewRepositoryProvider);
  final result = existing == null
      ? await repository.submitReview(
          id: item.id,
          type: item.type,
          body: controller.text,
          hasSpoiler: hasSpoiler,
        )
      : await repository.editReview(
          reviewId: existing.id,
          body: controller.text,
          hasSpoiler: hasSpoiler,
        );

  final failure = result.failureOrNull;
  if (failure != null && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }
}
