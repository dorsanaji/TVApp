import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/auth/presentation/auth_providers.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reproduction: Account B sees movies and request after Account A requests access', (tester) async {
    const accountB = AppUser(
      id: 'acc_b',
      email: 'b@example.com',
      username: 'user_b',
      firstName: 'User',
      lastName: 'B',
    );

    const accountA = AppUser(
      id: 'acc_a',
      email: 'a@example.com',
      username: 'user_a',
      firstName: 'User',
      lastName: 'A',
    );

    // Initial repo instance
    var repo = SupabaseSocialRepository(client: null);

    // 1. Account B creates list
    final listRes = await repo.createList(
      ownerId: accountB.id,
      title: 'Movies to Watch',
      isPublic: true,
    );
    final list = listRes.valueOrNull!;

    // 2. Account B adds movies
    const movie1 = MediaSummary(
      id: 101,
      type: MediaType.movie,
      title: 'Inception',
      posterPath: '/inception.jpg',
      voteAverage: 8.8,
    );
    const movie2 = MediaSummary(
      id: 102,
      type: MediaType.movie,
      title: 'Interstellar',
      posterPath: '/interstellar.jpg',
      voteAverage: 8.7,
    );

    await repo.addMovieToList(listId: list.listId, item: movie1, addedByUserId: accountB.id);
    await repo.addMovieToList(listId: list.listId, item: movie2, addedByUserId: accountB.id);

    // Verify Account B has 2 movies before request
    final beforeReq = await repo.getListItems(list.listId);
    expect(beforeReq.valueOrNull?.length, 2);

    // 3. User logs out and logs in as Account A
    // What if repo is recreated? e.g. New instance of SupabaseSocialRepository:
    repo = SupabaseSocialRepository(client: null);

    // 4. Account A sends access request
    await repo.requestCollaboratorAccess(listId: list.listId, userId: accountA.id);

    // 5. User logs out and logs back in as Account B
    // Again, what if repo is recreated on account switch?
    repo = SupabaseSocialRepository(client: null);

    // 6. Account B opens CollaborativeListScreen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWith((ref) => Stream.value(accountB)),
        ],
        child: MaterialApp(
          home: CollaborativeListScreen(listId: list.listId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check if movies are still there!
    final inceptionFinder = find.text('Inception');
    final interstellarFinder = find.text('Interstellar');
    final requestFinder = find.text('تأیید دسترسی');

    expect(inceptionFinder, findsOneWidget);
    expect(interstellarFinder, findsOneWidget);
    expect(requestFinder, findsOneWidget);
  });
}
