import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sign_in_prompt.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/media_summary.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../lists/presentation/add_to_list_sheet.dart';
import '../../../reviews/presentation/widgets/diary_entry_modal.dart';
import '../tracking_providers.dart';

/// The tracking controls shown on both detail screens.
///
/// Three requirements in one row, because they are one decision from the
/// user's point of view:
///  * FR-09 — the six watch statuses;
///  * FR-16 — favourite;
///  * FR-17 — add to a personal list.
class TrackingBar extends ConsumerWidget {
  const TrackingBar({required this.item, super.key});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (id: item.id, type: item.type);
    final status = ref.watch(watchStatusProvider(key)).valueOrNull;
    final isFavourite =
        ref.watch(isFavouriteProvider(key)).valueOrNull ?? false;
    final actions = ref.read(trackingActionsProvider);
    final signedIn = ref.watch(isSignedInProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => signedIn
                      ? _pickStatus(context, ref, status)
                      : showSignInPrompt(context, action: 'ثبت وضعیت تماشا'),
                  icon: Icon(_iconFor(status)),
                  label: Text(status?.label ?? 'ثبت وضعیت تماشا'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: AppStrings.statusFavourite,
                onPressed: () => signedIn
                    ? actions.toggleFavourite(item, favourite: !isFavourite)
                    : showSignInPrompt(
                        context,
                        action: 'افزودن به موردعلاقه‌ها',
                      ),
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: isFavourite ? Colors.redAccent : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'افزودن به فهرست',
                onPressed: () => signedIn
                    ? showAddToListSheet(context, item)
                    : showSignInPrompt(context, action: 'افزودن به فهرست'),
                icon: const Icon(Icons.playlist_add),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'دفترچه تماشا (Diary)',
                onPressed: () => signedIn
                    ? showDiaryEntryModal(context, item: item)
                    : showSignInPrompt(context, action: 'ثبت در دفترچه تماشا'),
                icon: const Icon(Icons.edit_calendar_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(WatchStatus? status) => switch (status) {
    null => Icons.add,
    WatchStatus.planToWatch => Icons.schedule,
    WatchStatus.watching => Icons.play_arrow_rounded,
    WatchStatus.watched => Icons.check_circle,
    WatchStatus.paused => Icons.pause_circle_outline,
    WatchStatus.dropped => Icons.cancel_outlined,
    WatchStatus.favourite => Icons.favorite,
  };

  Future<void> _pickStatus(
    BuildContext context,
    WidgetRef ref,
    WatchStatus? current,
  ) async {
    final actions = ref.read(trackingActionsProvider);

    final chosen = await showModalBottomSheet<_StatusChoice>(
      context: context,
      showDragHandle: true,
      // Seven rows plus a divider and the drag handle can exceed the default
      // sheet height once a device's navigation bar and font scale are taken
      // into account — it overflowed by 36px on a real phone, hiding the
      // "clear status" row entirely. Scroll control plus a height cap lets the
      // sheet grow to fit and scroll when it cannot (NFR-26).
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final status in WatchStatus.values)
                  ListTile(
                    leading: Icon(_iconFor(status)),
                    title: Text(status.label),
                    trailing: current == status
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () =>
                        Navigator.pop(context, _StatusChoice(status: status)),
                  ),
                if (current != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('حذف وضعیت'),
                    onTap: () => Navigator.pop(context, const _StatusChoice()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (chosen == null) return;
    await actions.setStatus(item, chosen.status);
  }
}

/// Distinguishes "the user picked a status" from "the user dismissed the
/// sheet", which a bare nullable `WatchStatus` cannot express — clearing the
/// status is itself a valid choice.
class _StatusChoice {
  const _StatusChoice({this.status});

  final WatchStatus? status;
}
