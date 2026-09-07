import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/collaboration_request.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/entities/social/custom_list_item.dart';
import 'package:cinetrack/domain/entities/social/list_collaborator.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

void main() {
  testWidgets('Test Owner with pending request and null fields', (tester) async {
    const list = CustomList(
      listId: 'test_list',
      ownerId: 'owner_user',
      title: 'Shared List',
      description: null,
      coverPath: null,
      itemCount: 1,
      collaboratorCount: 1,
    );

    final req = CollaborationRequest(
      requestId: 'req_1',
      listId: 'test_list',
      userId: 'requester_user',
      username: 'Requester',
      avatarUrl: null,
      createdAt: DateTime.now(),
      status: CollaborationRequestStatus.pending,
    );

    const item = CustomListItem(
      id: 'item_1',
      listId: 'test_list',
      mediaId: 123,
      mediaType: MediaType.movie,
      title: 'Test Movie',
      posterPath: null,
      overview: null,
      releaseDate: null,
      voteAverage: null,
      addedBy: null,
      addedAt: null,
    );

    const collab = ListCollaborator(
      listId: 'test_list',
      userId: 'collab_1',
      username: null,
      avatarUrl: null,
      addedAt: null,
    );

    const ownerUser = AppUser(
      id: 'owner_user',
      username: 'owner',
      firstName: 'Owner',
      lastName: 'User',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(ownerUser),
          collaborativeListStreamProvider('test_list').overrideWith((ref) => Stream.value(list)),
          collaborativeListDetailsProvider('test_list').overrideWith((ref) => Future.value(list)),
          collaborativeListItemsStreamProvider('test_list').overrideWith((ref) => Stream.value([item])),
          collaborativeListItemsProvider('test_list').overrideWith((ref) => Future.value([item])),
          listCollaboratorsStreamProvider('test_list').overrideWith((ref) => Stream.value([collab])),
          listCollaboratorsProvider('test_list').overrideWith((ref) => Future.value([collab])),
          collaborationRequestsStreamProvider('test_list').overrideWith((ref) => Stream.value([req])),
          collaborationRequestsProvider('test_list').overrideWith((ref) => Future.value([req])),
          isCollaboratorProvider('test_list').overrideWith((ref) => Future.value(true)),
        ],
        child: const MaterialApp(
          home: CollaborativeListScreen(listId: 'test_list'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test Non-owner with pending request and null fields', (tester) async {
    const list = CustomList(
      listId: 'test_list',
      ownerId: 'owner_user',
      title: 'Shared List',
      description: null,
      coverPath: null,
      itemCount: 1,
      collaboratorCount: 0,
    );

    final req = CollaborationRequest(
      requestId: 'req_1',
      listId: 'test_list',
      userId: 'requester_user',
      username: 'Requester',
      avatarUrl: null,
      createdAt: DateTime.now(),
      status: CollaborationRequestStatus.pending,
    );

    const nonOwnerUser = AppUser(
      id: 'requester_user',
      username: 'requester',
      firstName: 'Req',
      lastName: 'User',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(nonOwnerUser),
          collaborativeListStreamProvider('test_list').overrideWith((ref) => Stream.value(list)),
          collaborativeListDetailsProvider('test_list').overrideWith((ref) => Future.value(list)),
          collaborativeListItemsStreamProvider('test_list').overrideWith((ref) => Stream.value([])),
          collaborativeListItemsProvider('test_list').overrideWith((ref) => Future.value([])),
          listCollaboratorsStreamProvider('test_list').overrideWith((ref) => Stream.value([])),
          listCollaboratorsProvider('test_list').overrideWith((ref) => Future.value([])),
          collaborationRequestsStreamProvider('test_list').overrideWith((ref) => Stream.value([req])),
          collaborationRequestsProvider('test_list').overrideWith((ref) => Future.value([req])),
          isCollaboratorProvider('test_list').overrideWith((ref) => Future.value(false)),
        ],
        child: const MaterialApp(
          home: CollaborativeListScreen(listId: 'test_list'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
