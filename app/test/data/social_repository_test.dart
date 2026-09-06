import 'package:cinetrack/data/remote/supabase/supabase_mapper.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/social/public_profile.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SupabaseSocialRepository repository;

  setUp(() {
    repository = SupabaseSocialRepository(client: null); // in-memory fallback
  });

  group('Task 1 · SupabaseMapper', () {
    test('maps PublicProfile to and from map', () {
      const profile = PublicProfile(
        userId: 'u_1',
        username: 'cineaste',
        bio: 'film lover',
        totalWatched: 50,
        favoriteGenre: 'Sci-Fi',
      );

      final map = SupabaseMapper.profileToMap(profile);
      final restored = SupabaseMapper.profileFromMap(
        map,
        followers: 10,
        following: 5,
        isFollowing: true,
      );

      expect(restored.userId, profile.userId);
      expect(restored.username, profile.username);
      expect(restored.bio, profile.bio);
      expect(restored.totalWatched, profile.totalWatched);
      expect(restored.followersCount, 10);
      expect(restored.followingCount, 5);
      expect(restored.isFollowing, isTrue);
    });

    test('maps SocialActivity to and from map', () {
      final activity = SocialActivity(
        activityId: 'act_10',
        userId: 'u_1',
        actionType: SocialActionType.reviewed,
        movieId: 550,
        movieTitle: 'Fight Club',
        rating: 5.0,
        timestamp: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final map = SupabaseMapper.activityToMap(activity);
      final restored = SupabaseMapper.activityFromMap(map);

      expect(restored.activityId, activity.activityId);
      expect(restored.userId, activity.userId);
      expect(restored.actionType, SocialActionType.reviewed);
      expect(restored.movieId, 550);
      expect(restored.movieTitle, 'Fight Club');
      expect(restored.rating, 5.0);
    });
  });

  group('Task 1 · SupabaseSocialRepository CRUD Operations', () {
    test('upserts and retrieves public profile', () async {
      const profile = PublicProfile(
        userId: 'u_test_1',
        username: 'naji_haddadi',
        bio: 'Developer & Cinephile',
        totalWatched: 120,
        favoriteGenre: 'Drama',
      );

      final upsertResult = await repository.upsertProfile(profile);
      expect(upsertResult.isOk, isTrue);

      final fetchResult = await repository.getProfile('u_test_1');
      expect(fetchResult.isOk, isTrue);
      expect(fetchResult.valueOrNull?.username, 'naji_haddadi');
      expect(fetchResult.valueOrNull?.totalWatched, 120);
    });

    test('follow, unfollow, and query followers', () async {
      final followResult = await repository.followUser(
        followerId: 'u_1',
        followedId: 'u_2',
      );
      expect(followResult.isOk, isTrue);

      final isFollowingResult = await repository.isFollowing(
        followerId: 'u_1',
        followedId: 'u_2',
      );
      expect(isFollowingResult.valueOrNull, isTrue);

      final followedList = await repository.getFollowedUserIds('u_1');
      expect(followedList.valueOrNull, contains('u_2'));

      final unfollowResult = await repository.unfollowUser(
        followerId: 'u_1',
        followedId: 'u_2',
      );
      expect(unfollowResult.isOk, isTrue);

      final isFollowingAfter = await repository.isFollowing(
        followerId: 'u_1',
        followedId: 'u_2',
      );
      expect(isFollowingAfter.valueOrNull, isFalse);
    });

    test('custom list CRUD and collaborative operations', () async {
      // 1. Create list
      final createResult = await repository.createList(
        ownerId: 'u_1',
        title: 'شاهکارهای نولان',
        description: 'فیلم‌های کریستوفر نولان',
        isPublic: true,
      );
      expect(createResult.isOk, isTrue);
      final list = createResult.valueOrNull!;
      expect(list.title, 'شاهکارهای نولان');

      // 2. Add collaborator
      final addCollabRes = await repository.addCollaborator(
        listId: list.listId,
        userId: 'u_collab',
      );
      expect(addCollabRes.isOk, isTrue);

      final isCollab = await repository.isCollaborator(
        listId: list.listId,
        userId: 'u_collab',
      );
      expect(isCollab.valueOrNull, isTrue);

      // 3. Add movie to list
      const media = MediaSummary(
        id: 27205,
        type: MediaType.movie,
        title: 'Inception',
        posterPath: '/inception.jpg',
      );

      final addMovieRes = await repository.addMovieToList(
        listId: list.listId,
        item: media,
        addedByUserId: 'u_collab',
      );
      expect(addMovieRes.isOk, isTrue);

      final itemsRes = await repository.getListItems(list.listId);
      expect(itemsRes.valueOrNull?.length, 1);
      expect(itemsRes.valueOrNull?.first.title, 'Inception');

      // Test getCollaborativeListIdsContaining & getAllPublicLists
      final containingRes = await repository.getCollaborativeListIdsContaining(
        mediaId: 27205,
        mediaType: MediaType.movie,
      );
      expect(containingRes.valueOrNull, contains(list.listId));

      final publicListsRes = await repository.getAllPublicLists();
      expect(publicListsRes.valueOrNull?.any((l) => l.listId == list.listId), isTrue);

      // 4. Remove movie
      final removeMovieRes = await repository.removeMovieFromList(
        listId: list.listId,
        mediaId: 27205,
      );
      expect(removeMovieRes.isOk, isTrue);

      final containingAfter = await repository.getCollaborativeListIdsContaining(
        mediaId: 27205,
        mediaType: MediaType.movie,
      );
      expect(containingAfter.valueOrNull?.contains(list.listId), isFalse);

      final itemsAfter = await repository.getListItems(list.listId);
      expect(itemsAfter.valueOrNull?.isEmpty, isTrue);
    });

    test('logs and queries social activities feed', () async {
      final activity = SocialActivity(
        activityId: 'act_1',
        userId: 'u_friend',
        actionType: SocialActionType.watched,
        movieId: 550,
        movieTitle: 'Fight Club',
        timestamp: DateTime.now(),
        username: 'Ali',
      );

      final logRes = await repository.logActivity(activity);
      expect(logRes.isOk, isTrue);

      final feedRes = await repository.getActivityFeed(
        userIds: ['u_friend'],
      );
      expect(feedRes.isOk, isTrue);
      expect(feedRes.valueOrNull?.length, 1);
      expect(feedRes.valueOrNull?.first.movieTitle, 'Fight Club');
    });

    test('collaborator access request and approval workflow', () async {
      // 1. Create list by owner u_owner
      final createResult = await repository.createList(
        ownerId: 'u_owner',
        title: 'فهرست اشتراکی سینما',
        isPublic: true,
      );
      expect(createResult.isOk, isTrue);
      final list = createResult.valueOrNull!;

      // 2. Unauthorized user u_stranger tries to add movie -> should fail
      const movie = MediaSummary(
        id: 101,
        type: MediaType.movie,
        title: 'Interstellar',
      );
      final unauthorizedAdd = await repository.addMovieToList(
        listId: list.listId,
        item: movie,
        addedByUserId: 'u_stranger',
      );
      expect(unauthorizedAdd.isErr, isTrue);

      // 3. User u_stranger requests collaborator access
      final reqRes = await repository.requestCollaboratorAccess(
        listId: list.listId,
        userId: 'u_stranger',
      );
      expect(reqRes.isOk, isTrue);

      // 4. Owner queries pending requests
      final pendingReqs = await repository.getCollaborationRequests(list.listId);
      expect(pendingReqs.isOk, isTrue);
      expect(pendingReqs.valueOrNull?.length, 1);
      expect(pendingReqs.valueOrNull?.first.userId, 'u_stranger');

      // 5. Owner accepts the request
      final acceptRes = await repository.acceptCollaboratorRequest(
        listId: list.listId,
        userId: 'u_stranger',
      );
      expect(acceptRes.isOk, isTrue);

      // 6. User is now an accepted collaborator
      final isCollab = await repository.isCollaborator(
        listId: list.listId,
        userId: 'u_stranger',
      );
      expect(isCollab.valueOrNull, isTrue);

      // 7. Now accepted collaborator can add movie to the list
      final authorizedAdd = await repository.addMovieToList(
        listId: list.listId,
        item: movie,
        addedByUserId: 'u_stranger',
      );
      expect(authorizedAdd.isOk, isTrue);

      final items = await repository.getListItems(list.listId);
      expect(items.valueOrNull?.length, 1);
      expect(items.valueOrNull?.first.title, 'Interstellar');
    });
  });
}
