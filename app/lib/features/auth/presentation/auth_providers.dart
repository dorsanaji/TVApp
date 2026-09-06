import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/repositories/auth_repository.dart';

/// The signed-in user, or `null` for a guest (§4.1).
///
/// Seeded with whatever [LocalAuthRepository.restoreSession] found at startup,
/// so the first frame already knows whether a session survived — FR-02's
/// 30-day session must not require a visible re-login on every launch.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

/// Convenience for widgets that only need to know whether anyone is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  final async = ref.watch(currentUserProvider);
  return (async.valueOrNull ??
          ref.watch(authRepositoryProvider).currentUserOrNull) !=
      null;
});

/// FR-02 — whether the user opted into biometric re-authentication.
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isBiometricEnabled;
});
