import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/entities/social/list_collaborator.dart';
import 'package:cinetrack/domain/entities/social/public_profile.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:cinetrack/features/social/presentation/activity_feed_screen.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:cinetrack/features/social/presentation/public_profile_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

void main() {
  const testProfile = PublicProfile(
    userId: 'u_sara',
    username: 'sara_movie',
    bio: 'منتقد فیلم و نویسنده',
    totalWatched: 75,
    favoriteGenre: 'علمی‌تخیلی',
    followersCount: 120,
    followingCount: 45,
    isFollowing: false,
  );

  const testList = CustomList(
    listId: 'list_123',
    ownerId: 'u_sara',
    title: 'بهترین فیلم‌های ۲۰۲۴',
    description: 'گلچینی از فیلم‌های دیدنی امسال',
    isPublic: true,
    itemCount: 2,
    collaboratorCount: 1,
  );

  Widget createSubject({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
          ...authOverrides(),
        socialRepositoryProvider
            .overrideWithValue(SupabaseSocialRepository(client: null)),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  group('Task 3.1 · PublicProfileScreen Tests', () {
    testWidgets('renders user stats, public lists, and follow button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createSubject(
          overrides: [
          ...authOverrides(),
            publicProfileProvider('u_sara')
                .overrideWith((ref) => Future.value(testProfile)),
            userPublicListsProvider('u_sara')
                .overrideWith((ref) => Future.value([testList])),
          ],
          child: const PublicProfileScreen(userId: 'u_sara'),
        ),
      );
      await tester.pumpAndSettle();

      // Profile Header
      expect(find.text('sara_movie'), findsWidgets);
      expect(find.text('منتقد فیلم و نویسنده'), findsOneWidget);

      // Counters & Stats
      expect(find.text('دنبال‌کننده‌ها'), findsOneWidget);
      expect(find.text('دنبال‌شده‌ها'), findsOneWidget);
      expect(find.text('علمی‌تخیلی'), findsOneWidget);

      // Follow Button
      expect(find.text('دنبال کردن'), findsOneWidget);

      // Public Lists
      expect(find.text('بهترین فیلم‌های ۲۰۲۴'), findsOneWidget);
    });
  });

  group('Task 3.2 · CollaborativeListScreen Tests', () {
    testWidgets('renders list details, collaborator avatars, and FAB for collaborators', (tester) async {
      await tester.pumpWidget(
        createSubject(
          overrides: [
          ...authOverrides(),
            collaborativeListStreamProvider('list_123')
                .overrideWith((ref) => Stream.value(testList)),
            listCollaboratorsStreamProvider('list_123').overrideWith(
              (ref) => Stream.value([
                const ListCollaborator(
                  listId: 'list_123',
                  userId: 'u_collab',
                  username: 'رضا',
                ),
              ]),
            ),
            collaborativeListItemsStreamProvider('list_123').overrideWith(
              (ref) => Stream.value([]),
            ),
            isCollaboratorProvider('list_123')
                .overrideWith((ref) => Future.value(true)),
          ],
          child: const CollaborativeListScreen(listId: 'list_123'),
        ),
      );
      await tester.pumpAndSettle();

      // List Header
      expect(find.text('بهترین فیلم‌های ۲۰۲۴'), findsWidgets);
      expect(find.text('گلچینی از فیلم‌های دیدنی امسال'), findsOneWidget);

      // Collaborators
      expect(find.text('رضا'), findsOneWidget);

      // Verify add button is not present on shared list screen per design
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('افزودن فیلم یا سریال'), findsNothing);
    });
  });

  group('Task 3.3 · Activity feed tests', () {
    testWidgets('renders recent activities with Persian summary and Jalali time', (tester) async {
      final activity = SocialActivity(
        activityId: 'act_100',
        userId: 'u_sara',
        actionType: SocialActionType.reviewed,
        movieId: 550,
        movieTitle: 'باشگاه مبارزه',
        username: 'سارا',
        rating: 5.0,
        reviewText: 'شاهکار تکرارنشدنی دیوید فینچر!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        createSubject(
          overrides: [
          ...authOverrides(),
            activityFeedStreamProvider
                .overrideWith((ref) => Stream.value([activity])),
          ],
          child: const ActivityFeedView(),
        ),
      );
      await tester.pumpAndSettle();

      // The app bar belongs to the Social tab now, not to the feed itself.
      // Activity sentence
      expect(
        find.text('سارا فیلم «باشگاه مبارزه» را نقد کرد و به آن 5.0 ستاره داد'),
        findsOneWidget,
      );

      // Relative Jalali time (2 hours ago)
      expect(find.text('۲ ساعت پیش'), findsOneWidget);

      // Review snippet
      expect(find.text('«شاهکار تکرارنشدنی دیوید فینچر!»'), findsOneWidget);
    });
  });
}
