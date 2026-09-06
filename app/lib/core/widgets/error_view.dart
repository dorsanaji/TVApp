import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../l10n/app_strings.dart';
import '../theme/app_spacing.dart';

/// Renders a [Failure] with an icon, its Persian message, and a retry action.
///
/// This is the single presentation of FR-20. Because [Failure] is sealed, the
/// switch below is exhaustive — adding a new failure type will not compile
/// until it has been given an icon here, which is what stops an unhandled
/// error path from ever reaching the user as a blank screen.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.failure, this.onRetry, super.key});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (failure) {
    NoConnectionFailure() => Icons.wifi_off_rounded,
    NotFoundFailure() => Icons.search_off_rounded,
    ServiceUnavailableFailure() => Icons.cloud_off_rounded,
    UnauthorizedFailure() => Icons.lock_outline_rounded,
    ValidationFailure() => Icons.error_outline_rounded,
    StorageFailure() => Icons.sd_card_alert_outlined,
    FetchFailure() => Icons.error_outline_rounded,
  };
}
