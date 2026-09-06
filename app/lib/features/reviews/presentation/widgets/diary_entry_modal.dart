import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/l10n/persian_numbers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/poster_card.dart';
import '../../../../core/widgets/sign_in_prompt.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/media_summary.dart';
import '../../../../domain/entities/social/social_activity.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../tracking/presentation/tracking_providers.dart';
import '../review_providers.dart';

/// Shows the Letterboxd-style Diary Entry modal (Task 2).
Future<void> showDiaryEntryModal(
  BuildContext context, {
  required MediaSummary item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DiaryEntryModal(item: item),
  );
}

/// Task 2: Letterboxd-Style Diary & Jalali Calendar Modal.
///
/// Collects:
///  * Star rating (1–5)
///  * Watch date chosen with the Jalali (Shamsi) Date Picker
///  * "Rewatch" toggle (boolean)
///  * Written review (optional text)
///  * Spoiler toggle (boolean)
class DiaryEntryModal extends ConsumerStatefulWidget {
  const DiaryEntryModal({required this.item, super.key});

  final MediaSummary item;

  @override
  ConsumerState<DiaryEntryModal> createState() => _DiaryEntryModalState();
}

class _DiaryEntryModalState extends ConsumerState<DiaryEntryModal> {
  final _reviewController = TextEditingController();
  int _stars = 4;
  DateTime _watchedDate = DateTime.now();
  bool _isRewatch = false;
  bool _hasSpoiler = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing rating if already rated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = (id: widget.item.id, type: widget.item.type);
      final existingRating = ref.read(myRatingProvider(key)).valueOrNull;
      if (existingRating != null && mounted) {
        setState(() => _stars = existingRating);
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickJalaliDate() async {
    final initialJalali = Jalali.fromDateTime(_watchedDate);
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: initialJalali,
      firstDate: Jalali(1370, 1, 1),
      lastDate: Jalali.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _watchedDate = picked.toDateTime();
      });
    }
  }

  Future<void> _submit() async {
    final signedIn = ref.read(isSignedInProvider);
    if (!signedIn) {
      Navigator.pop(context);
      showSignInPrompt(context, action: 'ثبت در دفترچه تماشا');
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUserOrNull;

    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      final socialRepo = ref.read(socialRepositoryProvider);
      final trackingActions = ref.read(trackingActionsProvider);
      final item = widget.item;

      // 1. Submit star rating
      if (_stars > 0) {
        await reviewRepo.rate(item.id, item.type, _stars);
      }

      // 2. Submit optional review
      final reviewText = _reviewController.text.trim();
      if (reviewText.isNotEmpty) {
        await reviewRepo.submitReview(
          id: item.id,
          type: item.type,
          body: reviewText,
          hasSpoiler: _hasSpoiler,
        );
      }

      // 3. Mark as watched
      await trackingActions.setStatus(item, WatchStatus.watched);

      // 4. Log Social Activity
      final activity = SocialActivity(
        activityId: 'act_${DateTime.now().microsecondsSinceEpoch}',
        userId: currentUser.id,
        actionType: reviewText.isNotEmpty
            ? SocialActionType.reviewed
            : SocialActionType.watched,
        movieId: item.id,
        timestamp: _watchedDate,
        movieTitle: item.title,
        moviePoster: item.posterPath,
        username: currentUser.displayName,
        userAvatar: currentUser.avatarPath,
        rating: _stars > 0 ? _stars.toDouble() : null,
        reviewText: reviewText.isNotEmpty ? reviewText : null,
      );
      await socialRepo.logActivity(activity);

      // 5. Invalidate caches so UI updates immediately
      final key = (id: item.id, type: item.type);
      ref.invalidate(myRatingProvider(key));
      ref.invalidate(ratingSummaryProvider(key));
      ref.invalidate(reviewsProvider(key));
      ref.invalidate(watchStatusProvider(key));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRewatch
                  ? 'تماشای مجدد «${item.title}» در دفترچه ثبت شد'
                  : '«${item.title}» در دفترچه تماشا ثبت شد',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Media details ──────────────────────────────────
            Row(
              children: [
                PosterCard(
                  item: widget.item,
                  width: 56,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثبت در دفترچه تماشا (Diary)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.item.releaseDate != null)
                        Text(
                          Formatters.year(widget.item.releaseDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),

            // ── 1. Star Rating (1–5) ──────────────────────────────────
            Text(
              'امتیاز شما',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var s = 1; s <= 5; s++)
                  IconButton(
                    onPressed: () => setState(() => _stars = s),
                    icon: Icon(
                      _stars >= s
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: _stars >= s ? AppColors.star : null,
                      size: 36,
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${_stars.toPersian} از ۵',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 2. Jalali Date Picker ─────────────────────────────────
            Text(
              'تاریخ تماشا (تقویم شمسی)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _pickJalaliDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 20),
              label: Text(
                Formatters.formatJalaliDate(_watchedDate),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3. Rewatch Toggle ─────────────────────────────────────
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isRewatch,
              onChanged: (val) => setState(() => _isRewatch = val),
              secondary: Icon(
                Icons.replay_rounded,
                color: _isRewatch ? theme.colorScheme.primary : null,
              ),
              title: const Text('تماشای مجدد (Rewatch)'),
              subtitle: const Text('قبلاً این اثر را دیده‌ام'),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 4. Written Review (Optional) ──────────────────────────
            Text(
              'یادداشت یا نقد (اختیاری)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'نظرتان درباره این فیلم چیست؟...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // ── 5. Spoiler Toggle ─────────────────────────────────────
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _hasSpoiler,
              onChanged: (val) => setState(() => _hasSpoiler = val ?? false),
              title: const Text('این یادداشت حاوی اسپویل داستان است'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 6. Submit Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('ثبت در دفترچه تماشا'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
