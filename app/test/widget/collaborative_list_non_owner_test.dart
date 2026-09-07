import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/entities/social/custom_list_item.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

void main() {
  const otherUserList = CustomList(
    listId: 'list_other',
    ownerId: 'owner_user_id',
    title: 'فهرست کاربر دیگر',
    description: 'توضیحات فهرست کاربر دیگر',
    isPublic: true,
    itemCount: 1,
  );

  final testItem = CustomListItem(
    id: 'item_1',
    listId: 'list_other',
    mediaId: 550,
    mediaType: MediaType.movie,
    title: 'Fight Club',
    addedBy: 'owner_user_id',
    addedAt: DateTime.now(),
  );

  const currentUser = AppUser(
    id: 'my_user_id',
    username: 'من',
    firstName: 'علی',
    lastName: 'محمدی',
  );

  testWidgets('renders for non-owner non-collaborator user', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(currentUser),
          collaborativeListStreamProvider('list_other')
              .overrideWith((ref) => Stream.value(otherUserList)),
          collaborativeListDetailsProvider('list_other')
              .overrideWith((ref) => Future.value(otherUserList)),
          listCollaboratorsStreamProvider('list_other')
              .overrideWith((ref) => Stream.value([])),
          collaborativeListItemsStreamProvider('list_other')
              .overrideWith((ref) => Stream.value([testItem])),
          isCollaboratorProvider('list_other')
              .overrideWith((ref) => Future.value(false)),
          collaborationRequestsStreamProvider('list_other')
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: CollaborativeListScreen(listId: 'list_other'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('فهرست کاربر دیگر'), findsWidgets);
    expect(find.text('درخواست دسترسی'), findsOneWidget);
    expect(find.text('Fight Club'), findsWidgets);
  });
}
