import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../l10n/app_strings.dart';
import '../theme/app_spacing.dart';

/// Temporary screen body used by the Phase 1 shell.
///
/// It is not filler: it surfaces the delivery mode the build is running in
/// (§3.3) and the live count of duplicate requests suppressed by the
/// interceptor (NM-08, NFR-05) — an otherwise invisible requirement that
/// becomes demonstrable on camera for the submission video.
///
/// Each of these is replaced by the real screen in the phase named on it.
class PhasePlaceholder extends ConsumerWidget {
  const PhasePlaceholder({
    required this.title,
    required this.icon,
    required this.phase,
    required this.requirements,
    super.key,
  });

  final String title;
  final IconData icon;

  /// Which implementation phase delivers this screen.
  final String phase;

  /// Requirement IDs this screen will satisfy, e.g. `['FR-18']`.
  final List<String> requirements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dedup = ref.watch(dedupInterceptorProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.comingSoon,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final req in requirements)
                  Chip(
                    label: Text(req),
                    labelStyle: theme.textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: Text(phase),
                  labelStyle: theme.textTheme.labelSmall,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _InfoRow(
                  label: 'درخواست‌های تکراری جلوگیری‌شده',
                  value: '${dedup.suppressedCount}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
