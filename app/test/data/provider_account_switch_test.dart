import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/features/reviews/presentation/review_providers.dart';
import 'package:cinetrack/features/tracking/presentation/tracking_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Switching account must refresh what the screens show, not just what the
/// database returns.
///
/// Reported twice from the device: after signing in as B, the stars A had
/// given still appeared selected, and a favourite stayed lit after logging
/// out. The repositories were already scoped correctly — the *providers* were
/// not, because they watched only the data-change stream, and signing in or
/// out changes the account without changing any data.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late LocalAuthRepository auth;

  const dune = MediaSummary(id: 438631, type: MediaType.movie, title: 'Dune');
  const key = (id: 438631, type: MediaType.movie);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    auth = container.read(localAuthRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Keeps [provider] alive for the duration of a test and lets pending
  /// invalidations settle.
  ///
  /// Outside a widget tree nothing listens to a provider, so Riverpod may
  /// dispose it mid-flight; and the account change arrives on a stream, which
  /// needs a turn of the event loop to propagate. A running app supplies both
  /// naturally — widgets are the listeners, and frames are the settling point.
  void keepAlive(ProviderListenable<Object?> provider) {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  Future<void> signUp(String name) async {
    final result = await auth.register(
      firstName: name,
      lastName: 'تست',
      username: name,
      email: '$name@example.com',
      password: 'correct-horse',
    );
    expect(result.isOk, isTrue, reason: '${result.failureOrNull}');
  }

  test("account B does not see account A's rating", () async {
    keepAlive(myRatingProvider(key));

    await signUp('alice');
    await container
        .read(reviewRepositoryProvider)
        .rate(438631, MediaType.movie, 5);
    await settle();

    expect(await container.read(myRatingProvider(key).future), 5);

    await auth.logout();
    await signUp('bob');
    await settle();

    // Before the provider fix this still returned 5 — the repository was
    // right, the cached provider value was not.
    expect(
      await container.read(myRatingProvider(key).future),
      isNull,
      reason: "bob must not inherit alice's stars",
    );
  });

  test('a favourite does not stay lit after signing out', () async {
    keepAlive(isFavouriteProvider(key));

    await signUp('alice');
    await container
        .read(trackingRepositoryProvider)
        .setFavourite(dune, favourite: true);
    await settle();

    expect(await container.read(isFavouriteProvider(key).future), isTrue);

    await auth.logout();
    await settle();

    expect(
      await container.read(isFavouriteProvider(key).future),
      isFalse,
      reason: 'the heart must clear when the account does',
    );
  });

  test('profile counters follow the account', () async {
    keepAlive(profileCountersProvider);

    await signUp('alice');
    await container
        .read(trackingRepositoryProvider)
        .addToWatchlist(dune, WatchStatus.watched);
    await settle();

    final aliceCounters = await container.read(profileCountersProvider.future);
    expect(aliceCounters.moviesWatched, 1);

    await auth.logout();
    await signUp('bob');
    await settle();

    final bobCounters = await container.read(profileCountersProvider.future);
    expect(bobCounters.moviesWatched, 0);
  });

  test('counters update without needing to sign in again', () async {
    keepAlive(profileCountersProvider);

    await signUp('alice');
    await settle();
    expect(
      (await container.read(profileCountersProvider.future)).moviesWatched,
      0,
    );

    await container
        .read(trackingRepositoryProvider)
        .addToWatchlist(dune, WatchStatus.watched);
    await settle();

    // The counters used to come from the AppUser snapshot taken at sign-in, so
    // they stayed at zero until the next login.
    expect(
      (await container.read(profileCountersProvider.future)).moviesWatched,
      1,
    );
  });
}
