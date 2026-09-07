import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/error/result.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/watch_progress.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:cinetrack/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A signed-in account with no backend behind it.
///
/// Accounts live in Supabase Auth now, so anything that reads
/// `authRepositoryProvider` would otherwise reach for a client that does not
/// exist under `flutter test`. Widget tests care who is signed in, not how
/// they signed in, so this answers that one question and nothing else.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this._user]);

  final AppUser? _user;

  @override
  AppUser? get currentUserOrNull => _user;

  @override
  Stream<AppUser?> get currentUser => Stream.value(_user);

  @override
  bool get isBiometricEnabled => false;

  @override
  Future<Result<void>> setBiometricEnabled({required bool enabled}) async =>
      const Ok(null);

  @override
  Future<Result<bool>> authenticateBiometric() async => const Ok(true);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// The standard signed-in account for widget tests.
const testUser = AppUser(
  id: 'u1',
  username: 'tester',
  firstName: 'آریا',
  lastName: 'تست',
);

/// Overrides every provider that would otherwise need a live Supabase client
/// to answer "who is signed in".
///
/// Pass `null` to test the signed-out path.
List<Override> authOverrides([AppUser? user = testUser]) => [
  authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)),
  currentUserProvider.overrideWith((ref) => Stream.value(user)),
];


/// Tracking with nothing tracked.
///
/// Watch data lives in Supabase now, so a widget that only wants to know
/// "is this favourited?" would otherwise pull a whole client behind it.
class FakeTrackingRepository implements TrackingRepository {
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<Result<WatchStatus?>> statusOf(int id, MediaType type) async =>
      const Ok(null);

  @override
  Future<Result<bool>> isFavourite(int id, MediaType type) async =>
      const Ok(false);

  @override
  Future<Result<List<MediaSummary>>> watchlist(WatchlistSection section) async =>
      const Ok([]);

  @override
  Future<Result<UserStatistics>> statistics() async =>
      const Ok(UserStatistics());

  @override
  Future<Result<Map<int, WatchProgress>>> progressForAll(
    List<int> seriesIds,
  ) async => const Ok({});

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Auth plus the repositories that would otherwise reach for a live client.
List<Override> cloudOverrides([AppUser? user = testUser]) => [
  ...authOverrides(user),
  trackingRepositoryProvider.overrideWithValue(FakeTrackingRepository()),
];
