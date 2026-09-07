import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

void main() {
  testWidgets('Account B opens list with movies and access request from Account A', (tester) async {
    final repo = SupabaseSocialRepository(client: null);

    // 1. Account B creates a list and adds a movie
    const accountB = AppUser(
      id: 'account_b',
      username: 'user_b',
      firstName: 'User',
      lastName: 'B',
    );

    const accountA = AppUser(
      id: 'account_a',
      username: 'user_a',
      firstName: 'User',
      lastName: 'A',
    );

    final listRes = await repo.createList(
      ownerId: accountB.id,
      title: 'Watchlist B',
      isPublic: true,
    );
    final list = listRes.valueOrNull!;

    const movie = MediaSummary(
      id: 100,
      type: MediaType.movie,
      title: 'Inception',
      posterPath: '/inception.jpg',
      releaseDate: '2010-07-16',
      voteAverage: 8.8,
    );

    await repo.addMovieToList(
      listId: list.listId,
      item: movie,
      addedByUserId: accountB.id,
    );

    // 2. Account A sends access request to the list
    await repo.requestCollaboratorAccess(
      listId: list.listId,
      userId: accountA.id,
    );

    // 3. Account B opens the list screen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(accountB),
          socialRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: CollaborativeListScreen(listId: list.listId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify list title is shown
    expect(find.text('Watchlist B'), findsWidgets);

    // Verify requests are shown
    expect(find.text('درخواست‌های دسترسی به فهرست (۱):'), findsOneWidget);
    expect(find.text('تأیید دسترسی'), findsOneWidget);
    expect(find.text('رد'), findsOneWidget);

    // Verify movie is shown
    expect(find.text('Inception'), findsOneWidget);
  });
}
