import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_spacing.dart';

/// FR-02's biometric clause — "مگر آنکه کاربر درخواست کند ورود بیومتریک برای او
/// فعال شود" — enforced at the point it was promised.
///
/// The profile toggle says the app will ask on opening. Storing that preference
/// was only half of it: nothing ever called [AuthRepository.authenticateBiometric],
/// so the switch changed a flag and no prompt ever appeared. This wraps the
/// whole app so the promise is kept for every route, including one restored
/// from a deep link.
///
/// The decision is taken **once, in [initState]**, not watched. Reacting to the
/// preference would lock the user out of the very screen they used to turn it
/// on; "when opening the app" means at launch, and that is what this does.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  late bool _locked;
  bool _prompting = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final auth = ref.read(authRepositoryProvider);
    // Only a signed-in account has anything to protect. A guest holds no
    // personal data, and locking them out would leave no way back in.
    _locked = auth.isBiometricEnabled && auth.currentUserOrNull != null;

    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  Future<void> _authenticate() async {
    if (_prompting) return;
    setState(() {
      _prompting = true;
      _error = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .authenticateBiometric();

    if (!mounted) return;
    setState(() {
      _prompting = false;
      final failure = result.failureOrNull;
      if (failure != null) {
        _error = failure.message;
      } else if (result.valueOrNull ?? false) {
        _locked = false;
      } else {
        // Cancelled, or too many failed attempts. Not an error — the user may
        // simply have dismissed the sheet — so it gets a neutral message.
        _error = 'احراز هویت انجام نشد';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;

    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'برای ورود به برنامه احراز هویت کنید',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _prompting ? null : _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('تلاش دوباره'),
              ),
              const SizedBox(height: AppSpacing.sm),
              // The escape hatch, and not optional. A sensor that stops
              // recognising its owner — a changed lock screen, a wet finger, a
              // reset enrolment — would otherwise make the account permanently
              // unreachable. Signing out drops to the password form, which is
              // the FR-02 route that always works.
              TextButton(
                onPressed: _prompting
                    ? null
                    : () async {
                        await ref.read(authRepositoryProvider).logout();
                        if (mounted) setState(() => _locked = false);
                      },
                child: const Text('ورود با رمز عبور'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
