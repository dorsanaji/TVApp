import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/entities/social/custom_list_item.dart';
import 'package:cinetrack/domain/entities/social/list_collaborator.dart';
import 'package:cinetrack/domain/entities/social/public_profile.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task 1 · PublicProfile model', () {
    test('instantiates with expected fields and defaults', () {
      const profile = PublicProfile(
        userId: 'u_123',
        username: 'ali_cinema',
        avatarUrl: 'https://example.com/avatar.jpg',
        bio: 'عاشق سینمای کلاسیک',
        totalWatched: 42,
        favoriteGenre: 'درام',
        followersCount: 15,
        followingCount: 20,
        isFollowing: false,
      );

      expect(profile.userId, 'u_123');
      expect(profile.username, 'ali_cinema');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.bio, 'عاشق سینمای کلاسیک');
      expect(profile.totalWatched, 42);
      expect(profile.favoriteGenre, 'درام');
      expect(profile.followersCount, 15);
      expect(profile.followingCount, 20);
      expect(profile.isFollowing, isFalse);
    });

    test('copyWith updates specified fields correctly', () {
      const profile = PublicProfile(
        userId: 'u_123',
        username: 'ali',
        totalWatched: 10,
      );

      final updated = profile.copyWith(
        bio: 'بیوگرافی جدید',
        totalWatched: 11,
        isFollowing: true,
      );

      expect(updated.userId, 'u_123');
      expect(updated.username, 'ali');
      expect(updated.bio, 'بیوگرافی جدید');
      expect(updated.totalWatched, 11);
      expect(updated.isFollowing, isTrue);
    });
  });

  group('Task 1 · CustomList model', () {
    test('instantiates and verifies owner logic', () {
      const list = CustomList(
        listId: 'list_999',
        ownerId: 'u_123',
        title: 'شاهکارهای سینما',
        description: 'بهترین فیلم‌های تاریخ',
        isPublic: true,
        itemCount: 5,
        collaboratorCount: 2,
      );

      expect(list.listId, 'list_999');
      expect(list.ownerId, 'u_123');
      expect(list.title, 'شاهکارهای سینما');
      expect(list.isPublic, isTrue);
      expect(list.isOwner('u_123'), isTrue);
      expect(list.isOwner('u_456'), isFalse);
    });
  });

  group('Task 1 · ListCollaborator model', () {
    test('holds collaborator relationships', () {
      final now = DateTime.now();
      final collab = ListCollaborator(
        listId: 'list_999',
        userId: 'u_collab_1',
        username: 'sara',
        avatarUrl: 'https://example.com/sara.jpg',
        addedAt: now,
      );

      expect(collab.listId, 'list_999');
      expect(collab.userId, 'u_collab_1');
      expect(collab.username, 'sara');
      expect(collab.addedAt, now);
    });
  });

  group('Task 1 · SocialActivity model', () {
    test('generates accurate Persian sentence for reviewed action', () {
      final activity = SocialActivity(
        activityId: 'act_1',
        userId: 'u_123',
        actionType: SocialActionType.reviewed,
        movieId: 550,
        timestamp: DateTime.now(),
        username: 'علی',
        movieTitle: 'باشگاه مبارزه',
        rating: 4.5,
      );

      expect(
        activity.toPersianSentence(),
        'علی فیلم «باشگاه مبارزه» را نقد کرد و به آن 4.5 ستاره داد',
      );
    });

    test('generates accurate Persian sentence for watched action', () {
      final activity = SocialActivity(
        activityId: 'act_2',
        userId: 'u_123',
        actionType: SocialActionType.watched,
        movieId: 27205,
        timestamp: DateTime.now(),
        username: 'سارا',
        movieTitle: 'تلقین',
      );

      expect(
        activity.toPersianSentence(),
        'سارا فیلم «تلقین» را تماشا کرد',
      );
    });

    test('generates accurate Persian sentence for added_to_list action', () {
      final activity = SocialActivity(
        activityId: 'act_3',
        userId: 'u_123',
        actionType: SocialActionType.addedToList,
        movieId: 157336,
        timestamp: DateTime.now(),
        username: 'رضا',
        movieTitle: 'میان‌ستاره‌ای',
        listTitle: 'بهترین فیلم‌های علمی‌تخیلی',
      );

      expect(
        activity.toPersianSentence(),
        'رضا فیلم «میان‌ستاره‌ای» را به فهرست «بهترین فیلم‌های علمی‌تخیلی» افزود',
      );
    });
  });

  group('Task 1 · CustomListItem model', () {
    test('holds item attributes for collaborative lists', () {
      const item = CustomListItem(
        id: 'item_1',
        listId: 'list_999',
        mediaId: 100,
        mediaType: MediaType.movie,
        title: 'پدرخوانده',
        posterPath: '/godfather.jpg',
        addedBy: 'u_123',
      );

      expect(item.mediaId, 100);
      expect(item.title, 'پدرخوانده');
      expect(item.mediaType, MediaType.movie);
      expect(item.addedBy, 'u_123');
    });
  });
}
