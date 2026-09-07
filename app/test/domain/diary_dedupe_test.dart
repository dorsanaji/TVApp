import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_social_repository.dart';

/// The diary and the profile rails read the same activity log.
void main() {
  SocialActivity activity({
    required String id,
    required SocialActionType type,
    required int movieId,
    MediaType mediaType = MediaType.movie,
    required DateTime at,
  }) => SocialActivity(
    activityId: id,
    userId: 'u1',
    actionType: type,
    movieId: movieId,
    mediaType: mediaType,
    movieTitle: 'T$movieId',
    timestamp: at,
  );

  ProviderContainer containerWith(List<SocialActivity> activities) {
    final container = ProviderContainer(overrides: [
      socialRepositoryProvider
          .overrideWithValue(FakeSocialRepository(activities)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('one entry per title, keeping the newest', () async {
    final container = containerWith([
      activity(
        id: 'act_1',
        type: SocialActionType.diary,
        movieId: 97546,
        at: DateTime(2026, 9, 1),
      ),
      activity(
        id: 'diary_u1_movie_97546',
        type: SocialActionType.diary,
        movieId: 97546,
        at: DateTime(2026, 9, 5),
      ),
    ]);

    final diary = await container.read(userDiaryProvider('u1').future);

    expect(diary, hasLength(1));
    expect(diary.single.activityId, 'diary_u1_movie_97546');
  });

  test('the diary holds only diary entries', () async {
    final container = containerWith([
      activity(
        id: 'diary_u1_movie_5',
        type: SocialActionType.diary,
        movieId: 5,
        at: DateTime(2026, 9, 2),
      ),
      // None of these belong in a watch diary.
      activity(
        id: 'watch_u1_movie_6',
        type: SocialActionType.watched,
        movieId: 6,
        at: DateTime(2026, 9, 3),
      ),
      activity(
        id: 'review_u1_movie_7',
        type: SocialActionType.reviewed,
        movieId: 7,
        at: DateTime(2026, 9, 4),
      ),
      activity(
        id: 'follow_u1_u2',
        type: SocialActionType.followed,
        movieId: 0,
        at: DateTime(2026, 9, 5),
      ),
    ]);

    final diary = await container.read(userDiaryProvider('u1').future);

    expect(diary, hasLength(1));
    expect(diary.single.movieId, 5);
  });

  test('a title touched several ways appears once in recent titles', () async {
    final container = containerWith([
      activity(
        id: 'watch_u1_movie_5',
        type: SocialActionType.watched,
        movieId: 5,
        at: DateTime(2026, 9, 1),
      ),
      activity(
        id: 'review_u1_movie_5',
        type: SocialActionType.reviewed,
        movieId: 5,
        at: DateTime(2026, 9, 2),
      ),
      activity(
        id: 'add_u1_movie_5_list_1',
        type: SocialActionType.addedToList,
        movieId: 5,
        at: DateTime(2026, 9, 3),
      ),
    ]);

    final recent = await container.read(userRecentTitlesProvider('u1').future);

    expect(recent, hasLength(1));
  });

  test('a film and a series sharing an id are not merged', () async {
    final container = containerWith([
      activity(
        id: 'fav_u1_movie_550',
        type: SocialActionType.favourited,
        movieId: 550,
        at: DateTime(2026, 9, 1),
      ),
      activity(
        id: 'fav_u1_series_550',
        type: SocialActionType.favourited,
        movieId: 550,
        mediaType: MediaType.series,
        at: DateTime(2026, 9, 2),
      ),
    ]);

    final favourites = await container.read(userFavouritesProvider('u1').future);

    expect(favourites, hasLength(2));
  });

  test('one feed entry per title per person, showing the latest', () {
    // Watching a film, reviewing it and listing it is three rows about one
    // film — the feed used to print all three back to back.
    final rows = [
      activity(
        id: 'watch_u1_movie_5',
        type: SocialActionType.watched,
        movieId: 5,
        at: DateTime(2026, 9, 1),
      ),
      activity(
        id: 'review_u1_movie_5',
        type: SocialActionType.reviewed,
        movieId: 5,
        at: DateTime(2026, 9, 2),
      ),
      activity(
        id: 'add_u1_movie_5_list_1',
        type: SocialActionType.addedToList,
        movieId: 5,
        at: DateTime(2026, 9, 3),
      ),
    ];

    final collapsed = onePerTitlePerUserForTest(rows);

    expect(collapsed, hasLength(1));
    expect(collapsed.single.activityId, 'add_u1_movie_5_list_1');
  });

  test('two people watching the same film both show', () {
    final rows = [
      activity(
        id: 'watch_u1_movie_5',
        type: SocialActionType.watched,
        movieId: 5,
        at: DateTime(2026, 9, 1),
      ),
      SocialActivity(
        activityId: 'watch_u2_movie_5',
        userId: 'u2',
        actionType: SocialActionType.watched,
        movieId: 5,
        mediaType: MediaType.movie,
        movieTitle: 'T5',
        timestamp: DateTime(2026, 9, 2),
      ),
    ];

    expect(onePerTitlePerUserForTest(rows), hasLength(2));
  });

  test('follows are never collapsed together', () {
    final follows = [
      activity(
        id: 'follow_u1_u2',
        type: SocialActionType.followed,
        movieId: 0,
        at: DateTime(2026, 9, 1),
      ),
      activity(
        id: 'follow_u1_u3',
        type: SocialActionType.followed,
        movieId: 0,
        at: DateTime(2026, 9, 2),
      ),
    ];

    // Every follow carries movieId 0, so keying on the title would fold all
    // of someone's follows into a single line.
    expect(onePerTitlePerUserForTest(follows), hasLength(2));
  });

  test('favourites refresh when the activity revision moves', () async {
    final repo = FakeSocialRepository([]);
    final container = ProviderContainer(overrides: [
      socialRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final sub = container.listen(userFavouritesProvider('u1'), (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(userFavouritesProvider('u1').future), isEmpty);

    // Something is favourited after the first read.
    repo.activities.add(
      activity(
        id: 'fav_u1_movie_1',
        type: SocialActionType.favourited,
        movieId: 1,
        at: DateTime(2026, 9, 6),
      ),
    );
    container.read(socialActivityRevisionProvider.notifier).state++;

    expect(
      await container.read(userFavouritesProvider('u1').future),
      hasLength(1),
    );
  });
}
