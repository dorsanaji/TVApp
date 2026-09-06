import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../theme/app_spacing.dart';

/// Tells a guest that an action needs an account, and offers the way there.
///
/// §4.1 makes signing in a precondition for recording activity, ratings,
/// reviews and personal lists. The repositories enforce that by refusing the
/// write; this is the other half — without it a guest would tap a control and
/// see nothing happen, which reads as a broken app rather than a rule.
///
/// NFR-09 asks for clear error messages, and "nothing happened" is the least
/// clear message there is.
void showSignInPrompt(BuildContext context, {String? action}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        action == null
            ? 'برای این کار باید وارد حساب خود شوید'
            : 'برای $action باید وارد حساب خود شوید',
      ),
      action: SnackBarAction(
        label: 'ورود',
        onPressed: () {
          // Dismiss before navigating: a floating snackbar outlives the route
          // that showed it, so without this it hangs over the next screen.
          messenger.hideCurrentSnackBar();
          context.push(AppRoutes.login);
        },
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Full-screen version, for a tab a guest cannot use at all.
class SignInRequired extends StatelessWidget {
  const SignInRequired({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
      ),
    );
  }
}
