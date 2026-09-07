import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/data/repositories/local_list_repository.dart';
import 'package:cinetrack/data/repositories/local_review_repository.dart';
import 'package:cinetrack/data/repositories/local_tracking_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// NFR-16 — "users must only have access to their own permitted information".
///
/// Regression for a real defect found on device: every tracking table was
/// written and read under a hard-coded `'local'` owner, so a freshly
/// registered account inherited the previous account's watch statuses,
/// favourites, lists and profile counters.
///
/// The schema always had a `userId` column; nothing was ever written to it.
/// These tests fail loudly if that regresses.
void main() {
  late AppDatabase db;
  late LocalAuthRepository auth;
  late LocalTrackingRepository tracking;
  late LocalListRepository lists;
  late LocalReviewRepository reviews;

  const dune = MediaSummary(
    id: 438631,
    type: MediaType.movie,
    title: 'تل‌ماسه',
  );
  const breakingBad = MediaSummary(
    id: 1396,
    type: MediaType.series,
    title: 'بریکینگ بد',
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    auth = LocalAuthRepository(
      db: db,
      storage: const FlutterSecureStorage(),
    );
    tracking = LocalTrackingRepository(db, auth);
    lists = LocalListRepository(db, auth);
    reviews = LocalReviewRepository(db: db, auth: auth);
  });

  tearDown(() async {
    tracking.dispose();
    reviews.dispose();
    auth.dispose();
    await db.close();
  });

  Future<void> signUp(String username) async {
    final result = await auth.register(
      firstName: username,
      lastName: 'تست',
      username: username,
      password: 'correct-horse',
    );
    expect(result.isOk, isTrue, reason: '${result.failureOrNull}');
  }

  test(
    'a new account starts with no tracking data from the previous one',
    () async {
      // First user builds up a history.
      await signUp('alice');
      await tracking.addToWatchlist(dune, WatchStatus.watched);
      await tracking.addToWatchlist(breakingBad, WatchStatus.watching);
      await tracking.setFavourite(dune, favourite: true);
      await tracking.setEpisodeWatched(1396, 101, watched: true);

      expect(
        (await tracking.watchlist(WatchlistSection.watched)).valueOrNull,
        hasLength(1),
      );

      // Second user registers on the same device.
      await auth.logout();
      await signUp('bob');

      // This is the bug the user reported: bob saw alice's data.
      expect(
        (await tracking.watchlist(WatchlistSection.watched)).valueOrNull,
        isEmpty,
        reason:
            'a new account must not inherit the previous account\'s watchlist',
      );
      expect(
        (await tracking.watchlist(WatchlistSection.watching)).valueOrNull,
        isEmpty,
      );
      expect((await tracking.favourites()).valueOrNull, isEmpty);
      expect((await tracking.watchedEpisodeIds(1396)).valueOrNull, isEmpty);
      expect((await tracking.statusOf(dune.id, dune.type)).valueOrNull, isNull);
    },
  );

  test(
    'the first account keeps its data after the second one signs in',
    () async {
      await signUp('alice');
      await tracking.addToWatchlist(dune, WatchStatus.watched);

      await auth.logout();
      await signUp('bob');
      await tracking.addToWatchlist(breakingBad, WatchStatus.watched);

      // Back to alice — isolation must cut both ways, and nothing may be lost.
      await auth.logout();
      await auth.login(username: 'alice', password: 'correct-horse');

      final aliceItems = (await tracking.watchlist(
        WatchlistSection.watched,
      )).valueOrNull!;
      expect(aliceItems.map((i) => i.id), [dune.id]);
    },
  );

  test('personal lists are private to their owner', () async {
    await signUp('alice');
    final created = await lists.createList(name: 'بهترین فیلم‌های اکشن');
    final listId = created.valueOrNull!.id;
    await lists.addToList(listId, dune);

    expect((await lists.lists()).valueOrNull, hasLength(1));

    await auth.logout();
    await signUp('bob');

    expect((await lists.lists()).valueOrNull, isEmpty);
    // The "add to list" sheet must not report membership in someone else's
    // list either.
    expect(
      (await lists.listIdsContaining(dune.id, dune.type)).valueOrNull,
      isEmpty,
    );
  });

  test('ratings are private to their owner', () async {
    await signUp('alice');
    await reviews.rate(dune.id, dune.type, 5);

    await auth.logout();
    await signUp('bob');

    expect((await reviews.myRating(dune.id, dune.type)).valueOrNull, isNull);

    // The aggregate is deliberately cross-user — it is the "امتیاز کاربران
    // اپلیکیشن" of FR-06 — so alice's vote still counts towards the total.
    final summary = (await reviews.ratingSummary(
      dune.id,
      dune.type,
    )).valueOrNull!;
    expect(summary.total, 1);
  });

  test('profile counters report only the signed-in account', () async {
    await signUp('alice');
    await tracking.addToWatchlist(dune, WatchStatus.watched);
    await tracking.setFavourite(dune, favourite: true);

    // Counters are derived on read, so re-reading the user refreshes them.
    await auth.logout();
    await auth.login(username: 'alice', password: 'correct-horse');
    expect(auth.currentUserOrNull!.moviesWatchedCount, 1);
    expect(auth.currentUserOrNull!.favouritesCount, 1);

    await auth.logout();
    await signUp('bob');

    // Before the fix these queries had no WHERE user_id clause at all, so
    // bob's brand-new profile reported alice's totals.
    expect(auth.currentUserOrNull!.moviesWatchedCount, 0);
    expect(auth.currentUserOrNull!.seriesFollowedCount, 0);
    expect(auth.currentUserOrNull!.favouritesCount, 0);
  });

  test('statistics are scoped to the signed-in account', () async {
    await signUp('alice');
    await tracking.addToWatchlist(dune, WatchStatus.watched);
    await tracking.setEpisodeWatched(
      1396,
      101,
      watched: true,
      runtimeMinutes: 58,
    );

    final aliceStats = (await tracking.statistics()).valueOrNull!;
    expect(aliceStats.moviesWatched, 1);
    expect(aliceStats.episodesWatched, 1);

    await auth.logout();
    await signUp('bob');

    final bobStats = (await tracking.statistics()).valueOrNull!;
    expect(bobStats.moviesWatched, 0);
    expect(bobStats.episodesWatched, 0);
    expect(bobStats.totalMinutesWatched, 0);
  });

  group('§4.1 · recording activity requires an account', () {
    test('a guest cannot record a watch status', () async {
      final result = await tracking.addToWatchlist(dune, WatchStatus.watched);

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(
        (await tracking.watchlist(WatchlistSection.watched)).valueOrNull,
        isEmpty,
      );
    });

    test('a guest cannot favourite, mark episodes, or create lists', () async {
      expect(
        (await tracking.setFavourite(dune, favourite: true)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      expect(
        (await tracking.setEpisodeWatched(
          1396,
          101,
          watched: true,
        )).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      expect(
        (await lists.createList(name: 'هرچیزی')).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
    });

    test('a guest may still browse — reads are open, per §4.1', () async {
      // Guests search and view titles; only recording is gated.
      expect((await tracking.watchlist(WatchlistSection.watched)).isOk, isTrue);
      expect((await lists.lists()).isOk, isTrue);
      expect((await tracking.statistics()).isOk, isTrue);
    });

    test('signing in unlocks recording', () async {
      await signUp('alice');

      expect(
        (await tracking.addToWatchlist(dune, WatchStatus.watched)).isOk,
        isTrue,
      );
    });
  });
}
