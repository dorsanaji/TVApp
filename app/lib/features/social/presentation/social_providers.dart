import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/social/collaboration_request.dart';
import '../../../domain/entities/social/custom_list.dart';
import '../../../domain/entities/social/custom_list_item.dart';
import '../../../domain/entities/social/list_collaborator.dart';
import '../../../domain/entities/social/public_profile.dart';
import '../../../domain/entities/social/social_activity.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../tracking/presentation/tracking_providers.dart';

// ── Profile & Following Providers ────────────────────────────────────────

/// Fetches a user's public profile by user ID.
final publicProfileProvider =
    FutureProvider.family<PublicProfile, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;

  final profileRes = await repository.getProfile(userId);
  final profile = switch (profileRes) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };

  if (currentUserId != null && currentUserId != profile.userId) {
    final followingRes = await repository.isFollowing(
      followerId: currentUserId,
      followedId: profile.userId,
    );
    final isFollowing = followingRes.valueOrNull ?? false;
    return profile.copyWith(isFollowing: isFollowing);
  }

  return profile;
});

/// Public custom lists of a specific user.
final userPublicListsProvider =
    FutureProvider.family<List<CustomList>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getPublicListsOfUser(userId);
  return switch (res) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Checks whether the signed-in user is following [targetUserId].
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;
  if (currentUserId == null || currentUserId == targetUserId) return false;

  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.isFollowing(
    followerId: currentUserId,
    followedId: targetUserId,
  );
  return res.valueOrNull ?? false;
});

/// Followed user IDs for the current signed-in user.
final myFollowedUserIdsProvider = FutureProvider<List<String>>((ref) async {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;
  if (currentUserId == null) return const [];

  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getFollowedUserIds(currentUserId);
  return res.valueOrNull ?? const [];
});

/// Searches users by query or returns discoverable users when query is empty.
final userSearchProvider =
    FutureProvider.family<List<PublicProfile>, String>((ref, query) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.searchUsers(query);
  return res.valueOrNull ?? const [];
});

/// Fetches the watched movies and diary activities of [userId].
final userWatchedActivitiesProvider =
    FutureProvider.family<List<SocialActivity>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getUserActivities(userId);
  return res.valueOrNull ?? const [];
});

// ── Collaborative List Providers ─────────────────────────────────────────

/// Direct REST fetch of a CustomList's details (acts as fallback and instant loader for stream).
final collaborativeListDetailsProvider =
    FutureProvider.family<CustomList, String>((ref, listId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getList(listId);
  return switch (res) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Direct REST fetch of items inside a collaborative list.
final collaborativeListItemsProvider =
    FutureProvider.family<List<CustomListItem>, String>((ref, listId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getListItems(listId);
  return res.valueOrNull ?? const [];
});

/// Real-time stream of a CustomList's details.
final collaborativeListStreamProvider =
    StreamProvider.family<CustomList?, String>((ref, listId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchList(listId);
});

/// Direct REST fetch of collaborators for a list.
final listCollaboratorsProvider =
    FutureProvider.family<List<ListCollaborator>, String>((ref, listId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getCollaborators(listId);
  return res.valueOrNull ?? const [];
});

/// Real-time stream of collaborators for a list.
final listCollaboratorsStreamProvider =
    StreamProvider.family<List<ListCollaborator>, String>((ref, listId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchCollaborators(listId);
});

/// Direct REST fetch of pending access requests for [listId].
final collaborationRequestsProvider =
    FutureProvider.family<List<CollaborationRequest>, String>((ref, listId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getCollaborationRequests(listId);
  return res.valueOrNull ?? const [];
});

/// Real-time stream of pending access requests for [listId].
final collaborationRequestsStreamProvider =
    StreamProvider.family<List<CollaborationRequest>, String>((ref, listId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchCollaborationRequests(listId);
});

/// Checks if the signed-in user has a pending access request for [listId].
final hasPendingRequestProvider =
    Provider.family<bool, String>((ref, listId) {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;
  if (currentUserId == null) return false;

  final requests =
      ref.watch(collaborationRequestsStreamProvider(listId)).valueOrNull ??
          ref.watch(collaborationRequestsProvider(listId)).valueOrNull ??
          const [];
  return requests.any((r) =>
      r.userId == currentUserId &&
      r.status == CollaborationRequestStatus.pending);
});

/// Real-time stream of movie/series items inside a collaborative list.
final collaborativeListItemsStreamProvider =
    StreamProvider.family<List<CustomListItem>, String>((ref, listId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchListItems(listId);
});

/// Checks if current user is an owner or collaborator of [listId].
final isCollaboratorProvider =
    FutureProvider.family<bool, String>((ref, listId) async {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;
  if (currentUserId == null) return false;

  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.isCollaborator(
    listId: listId,
    userId: currentUserId,
  );
  return res.valueOrNull ?? false;
});

/// All collaborative / custom lists accessible to the signed-in user.
final myCollaborativeListsProvider = FutureProvider<List<CustomList>>((ref) async {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ??
      ref.watch(authRepositoryProvider).currentUserOrNull?.id;
  if (currentUserId == null) return const [];

  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getUserAccessibleLists(currentUserId);
  return switch (res) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// All public collaborative lists across the app.
final allPublicCollaborativeListsProvider =
    FutureProvider<List<CustomList>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getAllPublicLists();
  return res.valueOrNull ?? const [];
});

/// All collaborative lists accessible to the current user (owned, collaborated, or public).
final allAvailableCollaborativeListsProvider =
    FutureProvider<List<CustomList>>((ref) async {
  final userLists = await ref.watch(myCollaborativeListsProvider.future);
  final publicLists =
      await ref.watch(allPublicCollaborativeListsProvider.future);

  final map = <String, CustomList>{};
  for (final l in userLists) {
    map[l.listId] = l;
  }
  for (final l in publicLists) {
    map.putIfAbsent(l.listId, () => l);
  }
  return map.values.toList();
});

/// Set of collaborative list IDs that currently contain a given media item.
final collaborativeListsContainingProvider =
    FutureProvider.family<Set<String>, MediaKey>((ref, key) async {
  final repo = ref.watch(socialRepositoryProvider);
  final res = await repo.getCollaborativeListIdsContaining(
    mediaId: key.id,
    mediaType: key.type,
  );
  return res.valueOrNull ?? const {};
});


// ── Activity Feed Providers ──────────────────────────────────────────────

/// Real-time activity feed for users followed by the current user.
final activityFeedStreamProvider =
    StreamProvider<List<SocialActivity>>((ref) async* {
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (currentUserId == null) {
    yield const [];
    return;
  }

  final repository = ref.watch(socialRepositoryProvider);
  final followedIds =
      await ref.watch(myFollowedUserIdsProvider.future);

  // Include own activities as well so the user immediately sees their updates
  final allIds = {...followedIds, currentUserId}.toList();

  yield* repository.watchActivityFeed(allIds);
});

// ── Actions Provider ─────────────────────────────────────────────────────

final socialActionsProvider = Provider<SocialActions>((ref) {
  return SocialActions(ref);
});

class SocialActions {
  const SocialActions(this._ref);
  final Ref _ref;

  Future<Result<void>> toggleFollow(String targetUserId, {required bool follow}) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final repo = _ref.read(socialRepositoryProvider);
    final result = follow
        ? await repo.followUser(
            followerId: currentUserId,
            followedId: targetUserId,
          )
        : await repo.unfollowUser(
            followerId: currentUserId,
            followedId: targetUserId,
          );

    _ref.invalidate(isFollowingProvider(targetUserId));
    _ref.invalidate(publicProfileProvider(targetUserId));
    _ref.invalidate(myFollowedUserIdsProvider);
    return result;
  }

  Future<Result<CustomList>> createList({
    required String title,
    String? description,
    bool isPublic = true,
  }) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.createList(
      ownerId: currentUserId,
      title: title,
      description: description,
      isPublic: isPublic,
    );

    _ref.invalidate(userPublicListsProvider(currentUserId));
    _ref.invalidate(myCollaborativeListsProvider);
    return res;
  }

  Future<Result<void>> deleteList(String listId) async {
    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.deleteList(listId);
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId != null) {
      _ref.invalidate(myCollaborativeListsProvider);
      _ref.invalidate(userPublicListsProvider(currentUserId));
    }
    return res;
  }

  Future<Result<void>> requestCollaboratorAccess({
    required String listId,
  }) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final res = await _ref
        .read(socialRepositoryProvider)
        .requestCollaboratorAccess(listId: listId, userId: currentUserId);
    _ref.invalidate(collaborationRequestsStreamProvider(listId));
    _ref.invalidate(collaborationRequestsProvider(listId));
    return res;
  }

  Future<Result<void>> cancelCollaboratorRequest({
    required String listId,
  }) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final res = await _ref
        .read(socialRepositoryProvider)
        .cancelCollaboratorRequest(listId: listId, userId: currentUserId);
    _ref.invalidate(collaborationRequestsStreamProvider(listId));
    _ref.invalidate(collaborationRequestsProvider(listId));
    return res;
  }

  Future<Result<void>> acceptCollaboratorRequest({
    required String listId,
    required String userId,
  }) async {
    final res = await _ref
        .read(socialRepositoryProvider)
        .acceptCollaboratorRequest(listId: listId, userId: userId);
    _ref.invalidate(listCollaboratorsStreamProvider(listId));
    _ref.invalidate(listCollaboratorsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(isCollaboratorProvider(listId));
    _ref.invalidate(collaborationRequestsStreamProvider(listId));
    _ref.invalidate(collaborationRequestsProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(allAvailableCollaborativeListsProvider);
    return res;
  }

  Future<Result<void>> rejectCollaboratorRequest({
    required String listId,
    required String userId,
  }) async {
    final res = await _ref
        .read(socialRepositoryProvider)
        .rejectCollaboratorRequest(listId: listId, userId: userId);
    _ref.invalidate(collaborationRequestsStreamProvider(listId));
    _ref.invalidate(collaborationRequestsProvider(listId));
    return res;
  }

  Future<Result<void>> addCollaborator({
    required String listId,
    required String userId,
  }) async {
    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.addCollaborator(listId: listId, userId: userId);
    _ref.invalidate(listCollaboratorsStreamProvider(listId));
    _ref.invalidate(listCollaboratorsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(isCollaboratorProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    return res;
  }

  Future<Result<void>> removeCollaborator({
    required String listId,
    required String userId,
  }) async {
    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.removeCollaborator(listId: listId, userId: userId);
    _ref.invalidate(listCollaboratorsStreamProvider(listId));
    _ref.invalidate(listCollaboratorsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(isCollaboratorProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    return res;
  }

  Future<Result<void>> addMovieToList({
    required String listId,
    required MediaSummary item,
  }) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.addMovieToList(
      listId: listId,
      item: item,
      addedByUserId: currentUserId,
    );

    // Asynchronously log activity without blocking the return response,
    // using a deterministic activity ID to eliminate spam/duplicate entries
    unawaited(() async {
      try {
        final listRes = await repo.getList(listId);
        final listTitle = listRes.valueOrNull?.title;
        final user = _ref.read(currentUserProvider).valueOrNull ??
            _ref.read(authRepositoryProvider).currentUserOrNull;

        await repo.logActivity(
          SocialActivity(
            activityId: 'add_${currentUserId}_${item.id}_$listId',
            userId: currentUserId,
            actionType: SocialActionType.addedToList,
            movieId: item.id,
            movieTitle: item.title,
            moviePoster: item.posterPath,
            username: user?.displayName,
            userAvatar: user?.avatarPath,
            listTitle: listTitle,
            timestamp: DateTime.now(),
          ),
        );
        _ref.invalidate(userWatchedActivitiesProvider(currentUserId));
      } catch (_) {}
    }());

    _ref.invalidate(collaborativeListItemsStreamProvider(listId));
    _ref.invalidate(collaborativeListItemsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(allPublicCollaborativeListsProvider);
    _ref.invalidate(allAvailableCollaborativeListsProvider);
    _ref.invalidate(
      collaborativeListsContainingProvider((id: item.id, type: item.type)),
    );
    return res;
  }

  Future<Result<void>> removeMovieFromList({
    required String listId,
    required int mediaId,
    MediaType? mediaType,
  }) async {
    final repo = _ref.read(socialRepositoryProvider);
    final res = await repo.removeMovieFromList(
      listId: listId,
      mediaId: mediaId,
    );
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId != null) {
      _ref.invalidate(userWatchedActivitiesProvider(currentUserId));
    }

    _ref.invalidate(collaborativeListItemsStreamProvider(listId));
    _ref.invalidate(collaborativeListItemsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(allPublicCollaborativeListsProvider);
    _ref.invalidate(allAvailableCollaborativeListsProvider);
    if (mediaType != null) {
      _ref.invalidate(
        collaborativeListsContainingProvider((id: mediaId, type: mediaType)),
      );
    }
    return res;
  }
}
