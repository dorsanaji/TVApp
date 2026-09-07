import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/data/repositories/local_review_repository.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A diary entry is private; a comment is public. They must not leak into
/// each other.
void main() {
  late AppDatabase db;
  late LocalAuthRepository auth;
  late LocalReviewRepository reviews;
  late SupabaseSocialRepository social;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SupabaseSocialRepository.resetMockStorage();
    db = AppDatabase(NativeDatabase.memory());
    auth = LocalAuthRepository(
      db: db,
      storage: const FlutterSecureStorage(),
    );
    reviews = LocalReviewRepository(db: db, auth: auth);
    social = SupabaseSocialRepository(client: null);

    final registered = await auth.register(
      firstName: 'آریا',
      lastName: 'تست',
      username: 'tester',
      password: 'correct-horse',
    );
    expect(registered.isOk, isTrue, reason: '${registered.failureOrNull}');
  });

  tearDown(() async {
    reviews.dispose();
    auth.dispose();
    await db.close();
  });

  test('a diary entry publishes no review under the title', () async {
    // What the diary modal writes: a diary activity, and nothing in Reviews.
    await social.logActivity(
      SocialActivity(
        activityId: SocialActivity.buildId(
          prefix: 'diary',
          userId: 'u1',
          mediaType: MediaType.movie,
          mediaId: 550,
        ),
        userId: 'u1',
        actionType: SocialActionType.diary,
        movieId: 550,
        mediaType: MediaType.movie,
        timestamp: DateTime(2026, 2, 24),
        movieTitle: 'باشگاه مبارزه',
        rating: 2,
        reviewText: 'برای خودم: خسته‌کننده بود.',
      ),
    );

    final published = await reviews.reviews(550, MediaType.movie);

    expect(
      published.valueOrNull,
      isEmpty,
      reason: 'a diary note must never appear under the film',
    );
  });

  test('diary entries are kept out of the friends feed', () async {
    for (final type in [SocialActionType.diary, SocialActionType.reviewed]) {
      await social.logActivity(
        SocialActivity(
          activityId: '${type.value}_u1_movie_550',
          userId: 'u1',
          actionType: type,
          movieId: 550,
          mediaType: MediaType.movie,
          timestamp: DateTime(2026, 2, 24),
          movieTitle: 'باشگاه مبارزه',
        ),
      );
    }

    final feed = await social.getActivityFeed(userIds: ['u1']);
    final types = (feed.valueOrNull ?? []).map((a) => a.actionType).toSet();

    expect(types, contains(SocialActionType.reviewed));
    expect(
      types,
      isNot(contains(SocialActionType.diary)),
      reason: 'the diary is not a broadcast',
    );
  });
}
