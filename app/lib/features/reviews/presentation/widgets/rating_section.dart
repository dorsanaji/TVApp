import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/l10n/persian_numbers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/media_summary.dart';
import '../../../../domain/repositories/review_repository.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../review_providers.dart';

/// FR-13 §5.13 — rating.
///
/// Two halves, both of which the brief requires:
///  * a 1–5 star selector that edits an existing rating rather than adding a
///    second one;
///  * the distribution, showing **the percentage of each qualitative level
///    from 0 to 100**.
///
/// That second half is the part most often misread. It is a distribution
/// across the five levels which sums to 100 — not one average rescaled to a
/// percentage. See `test/domain/rating_summary_test.dart`.
class RatingSection extends ConsumerWidget {
  const RatingSection({required this.item, super.key});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final key = (id: item.id, type: item.type);
    final myRating = ref.watch(myRatingProvider(key)).valueOrNull;
    final summary = ref.watch(ratingSummaryProvider(key)).valueOrNull;
    final signedIn = ref.watch(isSignedInProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'امتیاز شما',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StarSelector(
            value: myRating,
            enabled: signedIn,
            onChanged: (stars) async {
              final repository = ref.read(reviewRepositoryProvider);
              // Tapping the current rating clears it, which is the only way to
              // undo a rating without a separate control.
              if (stars == myRating) {
                await repository.clearRating(item.id, item.type);
              } else {
                await repository.rate(item.id, item.type, stars);
              }
            },
          ),
          if (!signedIn)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'برای ثبت امتیاز باید وارد شوید',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (summary != null && summary.total > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'توزیع امتیازها',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Distribution(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _StarSelector extends StatelessWidget {
  const _StarSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int? value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: enabled ? () => onChanged(star) : null,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              (value ?? 0) >= star
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: (value ?? 0) >= star ? AppColors.star : null,
              size: 32,
            ),
          ),
        if (value != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${value!.toPersian} از ۵',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// The 0–100 percentage for each of the five levels.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Highest level first, which is how a rating histogram is normally read.
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Row(
                    children: [
                      Text(star.toPersian, style: theme.textTheme.labelSmall),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.star,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      // percentFor returns 0–100; the widget wants 0–1.
                      value: summary.percentFor(star) / 100,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${summary.percentFor(star).round().toPersian}٪',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'مجموع ${summary.total.toPersian} رأی',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
