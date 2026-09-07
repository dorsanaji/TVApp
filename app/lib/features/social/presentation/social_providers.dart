import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../../domain/entities/social/list_invite_code.dart';
import '../../../domain/entities/social/public_profile.dart';
import '../../../domain/entities/social/social_activity.dart';
import '../../../domain/repositories/social_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../tracking/presentation/tracking_providers.dart';

// ── Profile & Following Providers ────────────────────────────────────────

/// The follow state the user has asked for, before the server has confirmed
/// it. `null` means "no opinion — trust the profile".
///
/// Deliberately a provider rather than state inside the follow button: the
/// button and the follower count are showing the same fact, so they have to
/// move together. Auto-disposed, so leaving the profile drops the guess and
/// the next visit starts from whatever the server actually says.
final pendingFollowProvider =
    StateProvider.autoDispose.family<bool?, String>((ref, userId) => null);

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
///
/// Auto-disposed: a list's item count and cover change whenever anyone adds
/// or removes a title, and the owner is often not the person looking. Holding
/// the result for the life of the app left profiles showing a count and a
/// poster from before the change.
final userPublicListsProvider =
    FutureProvider.autoDispose.family<List<CustomList>, String>((
  ref,
  userId,
) async {
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
///
/// Auto-disposed: who exists changes on the server, and a result cached for
/// the life of the app kept listing accounts that had already been deleted.
/// Leaving the tab now drops the cache, so coming back re-reads.
final userSearchProvider =
    FutureProvider.autoDispose.family<List<PublicProfile>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.searchUsers(query);
  return res.valueOrNull ?? const [];
});

/// Everything [userId] has done, newest first — the diary's backing data.
///
/// A wider window than the feed's default, since the diary is meant to be
/// scrolled back through rather than glanced at.
final userActivitiesProvider =
    FutureProvider.autoDispose.family<List<SocialActivity>, String>((
  ref,
  userId,
) async {
  // Refetch when anything is logged, and drop the cache once nothing is
  // watching. Without both, a favourite written to Supabase sat behind a
  // value cached for the life of the app, so the profile and the diary only
  // caught up on a restart.
  ref.watch(socialActivityRevisionProvider);
  final repository = ref.watch(socialRepositoryProvider);
  final res = await repository.getUserActivities(userId, limit: 200);
  return res.valueOrNull ?? const [];
});

/// Collapses a person's activity on one title into a single feed entry.
///
/// Watching a film, rating it and adding it to a list are three rows, and the
/// feed was printing all three back to back — the same poster and the same
/// name three times over, which buries whatever else your friends did. The
/// newest wins, so the entry says the most recent thing that happened.
///
/// Follows are exempt: they all carry `movieId` 0, so keying them by title
/// would collapse every person someone followed into one line. Their ids are
/// already unique per pair.
@visibleForTesting
List<SocialActivity> onePerTitlePerUserForTest(List<SocialActivity> a) =>
    _onePerTitlePerUser(a);

List<SocialActivity> _onePerTitlePerUser(List<SocialActivity> activities) {
  final byKey = <String, SocialActivity>{};
  for (final activity in activities) {
    final key = activity.actionType == SocialActionType.followed
        ? activity.activityId
        : '${activity.userId}:'
            '${activity.mediaType?.name ?? 'movie'}:${activity.movieId}';
    final existing = byKey[key];
    if (existing == null || activity.timestamp.isAfter(existing.timestamp)) {
      byKey[key] = activity;
    }
  }
  return byKey.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}

/// The watch diary: what [userId] wrote for themselves, newest first.
///
/// Only diary entries — not watches, follows, favourites or list additions.
/// The diary is a dated record of what someone thought about what they saw,
/// which is a different thing from a log of every button they pressed.
final userDiaryProvider =
    FutureProvider.autoDispose.family<List<SocialActivity>, String>((
  ref,
  userId,
) async {
  final activities = await ref.watch(userActivitiesProvider(userId).future);

  // One entry per title: re-saving a diary entry updates it rather than
  // adding a second line for the same film.
  final byTitle = <String, SocialActivity>{};
  for (final activity in activities) {
    if (activity.actionType != SocialActionType.diary) continue;
    final key = '${activity.mediaType?.name ?? 'movie'}:${activity.movieId}';
    final existing = byTitle[key];
    if (existing == null || activity.timestamp.isAfter(existing.timestamp)) {
      byTitle[key] = activity;
    }
  }

  return byTitle.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

/// What [userId] has marked as a favourite.
final userFavouritesProvider =
    FutureProvider.autoDispose.family<List<SocialActivity>, String>((
  ref,
  userId,
) async {
  final activities = await ref.watch(userActivitiesProvider(userId).future);
  return _newestPerTitle(
    activities.where((a) => a.actionType == SocialActionType.favourited),
  );
});

/// What [userId] has watched, newest first and one entry per title.
final userWatchedTitlesProvider =
    FutureProvider.autoDispose.family<List<SocialActivity>, String>((
  ref,
  userId,
) async {
  final activities = await ref.watch(userActivitiesProvider(userId).future);
  return _newestPerTitle(
    activities.where((a) => a.actionType == SocialActionType.watched),
  );
});

/// Titles [userId] has touched recently in any way that says something about
/// their taste — watched, rated, reviewed, diarised, or added to a list.
///
/// One card per title however many of those happened: a film watched, rated
/// and listed is still one film, and three copies of its poster said nothing
/// extra.
final userRecentTitlesProvider =
    FutureProvider.autoDispose.family<List<SocialActivity>, String>((
  ref,
  userId,
) async {
  final activities = await ref.watch(userActivitiesProvider(userId).future);
  return _newestPerTitleId(
    activities.where(
      (a) =>
          a.actionType == SocialActionType.watched ||
          a.actionType == SocialActionType.reviewed ||
          a.actionType == SocialActionType.diary ||
          a.actionType == SocialActionType.addedToList,
    ),
  );
});

/// Like [_newestPerTitle] but keyed on the title id alone.
///
/// Activities for one film can disagree about its media type — rows written
/// before the type was recorded carry none — so keying on the pair would
/// split a single film across two cards. Whichever entry knows the type
/// supplies it, so the card still opens the right screen.
List<SocialActivity> _newestPerTitleId(Iterable<SocialActivity> activities) {
  final byId = <int, SocialActivity>{};
  for (final activity in activities) {
    final existing = byId[activity.movieId];
    if (existing == null || activity.timestamp.isAfter(existing.timestamp)) {
      byId[activity.movieId] = activity.mediaType == null
          ? activity.copyWith(mediaType: existing?.mediaType)
          : activity;
    } else if (existing.mediaType == null && activity.mediaType != null) {
      byId[activity.movieId] = existing.copyWith(mediaType: activity.mediaType);
    }
  }
  return byId.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}

/// One row per title, keeping the newest. Activities repeat — a film can be
/// watched, rated and listed — and a wall of the same poster is noise.
///
/// Keyed on the type as well as the id: TMDB numbers films and series in the
/// same space, so a film and a series can genuinely share an id and must not
/// collapse into one another.
List<SocialActivity> _newestPerTitle(Iterable<SocialActivity> activities) {
  final byTitle = <String, SocialActivity>{};
  for (final activity in activities) {
    final key = '${activity.mediaType?.name ?? 'movie'}:${activity.movieId}';
    final existing = byTitle[key];
    if (existing == null || activity.timestamp.isAfter(existing.timestamp)) {
      byTitle[key] = activity;
    }
  }
  final result = byTitle.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return result;
}

/// The profiles following [userId].
final followersProvider =
    FutureProvider.family<List<PublicProfile>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final ids = await repository.getFollowerUserIds(userId);
  return _profilesFor(repository, ids.valueOrNull ?? const []);
});

/// The profiles [userId] follows.
final followingProvider =
    FutureProvider.family<List<PublicProfile>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  final ids = await repository.getFollowedUserIds(userId);
  return _profilesFor(repository, ids.valueOrNull ?? const []);
});

Future<List<PublicProfile>> _profilesFor(
  SocialRepository repository,
  List<String> ids,
) async {
  final results = await Future.wait(
    ids.map((id) async => (await repository.getProfile(id)).valueOrNull),
  );
  return results.whereType<PublicProfile>().toList();
}

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

/// A request the user has just sent, before the server round trip finishes.
///
/// Same reason as [pendingFollowProvider]: sending a request writes a row and
/// then re-reads it, and until that finished the banner still offered to ask
/// for access, so the tap looked ignored.
final pendingAccessRequestProvider =
    StateProvider.autoDispose.family<bool?, String>((ref, listId) => null);

/// Checks if the signed-in user has a pending access request for [listId].
final hasPendingRequestProvider =
    Provider.family<bool, String>((ref, listId) {
  final optimistic = ref.watch(pendingAccessRequestProvider(listId));
  if (optimistic != null) return optimistic;

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
  final followedIds = await ref.watch(myFollowedUserIdsProvider.future);

  // Followed users only. The feed is for seeing what other people are up to;
  // your own activity is on your profile, and mixing it in here just pushed
  // theirs down the page.
  yield* repository
      .watchActivityFeed(
        followedIds.where((id) => id != currentUserId).toList(),
      )
      .map(_onePerTitlePerUser);
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

    // Record it so the diary can show who the user followed and when. An
    // unfollow removes the entry rather than adding a second one — the diary
    // is a record of what someone did, not a ledger of every reversal.
    unawaited(() async {
      try {
        final activityId = 'follow_${currentUserId}_$targetUserId';
        if (follow) {
          final me = _ref.read(currentUserProvider).valueOrNull ??
              _ref.read(authRepositoryProvider).currentUserOrNull;
          final target = await repo.getProfile(targetUserId);
          await repo.logActivity(
            SocialActivity(
              activityId: activityId,
              userId: currentUserId,
              actionType: SocialActionType.followed,
              movieId: 0,
              timestamp: DateTime.now(),
              // The activity row has no column for "who", so the followed
              // user's name rides along in the title field.
              movieTitle: target.valueOrNull?.username ?? 'کاربر',
              username: me?.displayName,
              userAvatar: me?.avatarPath,
            ),
          );
        } else {
          await repo.deleteActivity(activityId);
        }
      } catch (_) {}
    }());

    _ref.invalidate(isFollowingProvider(targetUserId));
    _ref.invalidate(publicProfileProvider(targetUserId));
    _ref.invalidate(myFollowedUserIdsProvider);
    _ref.read(socialActivityRevisionProvider.notifier).state++;
    return result;
  }

  /// Saves the genres the signed-in user says they like.
  ///
  /// Capped at [PublicProfile.maxFavouriteGenres]; passing an empty list
  /// clears the choice.
  Future<Result<void>> setFavouriteGenres(List<String> genres) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final repo = _ref.read(socialRepositoryProvider);
    final existing = await repo.getProfile(currentUserId);
    final profile = existing.valueOrNull;
    if (profile == null) {
      return Err(existing.failureOrNull ?? const NotFoundFailure());
    }

    final res = await repo.upsertProfile(
      profile.copyWith(
        favoriteGenre: PublicProfile.joinGenres(genres),
        clearFavoriteGenre: genres.isEmpty,
      ),
    );

    _ref.invalidate(publicProfileProvider(currentUserId));
    _ref.invalidate(publicProfileProvider(profile.userId));
    return res.isOk ? const Ok(null) : Err(res.failureOrNull!);
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

  /// Joins the list an invitation code points at.
  ///
  /// Returns the list on success so the caller can open it. A code is only a
  /// pointer — the list still has to exist, and joining is the same act as
  /// being accepted onto it, so the user becomes a full collaborator.
  Future<Result<CustomList>> joinListByCode(String code) async {
    final currentUserId = _ref.read(currentUserProvider).valueOrNull?.id ??
        _ref.read(authRepositoryProvider).currentUserOrNull?.id;
    if (currentUserId == null) {
      return const Err(UnauthorizedFailure());
    }

    final listId = ListInviteCode.toListId(code);
    if (listId == null) {
      return const Err(ValidationFailure('کد دعوت معتبر نیست'));
    }

    final repo = _ref.read(socialRepositoryProvider);
    final listRes = await repo.getList(listId);
    final list = listRes.valueOrNull;
    if (list == null) {
      return const Err(NotFoundFailure());
    }

    if (list.isOwner(currentUserId)) {
      return Ok(list);
    }

    final joined = await repo.addCollaborator(
      listId: listId,
      userId: currentUserId,
    );
    if (joined.isErr) {
      return Err(joined.failureOrNull ?? const FetchFailure());
    }

    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(listCollaboratorsProvider(listId));
    _ref.invalidate(listCollaboratorsStreamProvider(listId));
    _ref.invalidate(isCollaboratorProvider(listId));
    return Ok(list);
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

  /// Refreshes the public profile of whoever owns [listId].
  ///
  /// A collaborator can change a list they do not own, so invalidating only
  /// the signed-in user's profile would leave the owner's showing stale
  /// figures.
  void _invalidateOwnerProfileLists(String listId) {
    unawaited(() async {
      try {
        final list = await _ref.read(socialRepositoryProvider).getList(listId);
        final ownerId = list.valueOrNull?.ownerId;
        if (ownerId != null) {
          _ref.invalidate(userPublicListsProvider(ownerId));
        }
      } catch (_) {}
    }());
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
            activityId: SocialActivity.buildId(
              prefix: 'add',
              userId: currentUserId,
              mediaType: item.type,
              mediaId: item.id,
              suffix: listId,
            ),
            userId: currentUserId,
            actionType: SocialActionType.addedToList,
            movieId: item.id,
            mediaType: item.type,
            movieTitle: item.title,
            moviePoster: item.posterPath,
            username: user?.displayName,
            userAvatar: user?.avatarPath,
            listTitle: listTitle,
            timestamp: DateTime.now(),
          ),
        );
        _ref.read(socialActivityRevisionProvider.notifier).state++;
      } catch (_) {}
    }());

    _ref.invalidate(collaborativeListItemsStreamProvider(listId));
    _ref.invalidate(collaborativeListItemsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(allPublicCollaborativeListsProvider);
    _ref.invalidate(allAvailableCollaborativeListsProvider);
    // The list is drawn on its owner's profile too, with a count and a cover
    // that both just moved.
    _invalidateOwnerProfileLists(listId);
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
      _ref.read(socialActivityRevisionProvider.notifier).state++;
    }

    _ref.invalidate(collaborativeListItemsStreamProvider(listId));
    _ref.invalidate(collaborativeListItemsProvider(listId));
    _ref.invalidate(collaborativeListStreamProvider(listId));
    _ref.invalidate(collaborativeListDetailsProvider(listId));
    _ref.invalidate(myCollaborativeListsProvider);
    _ref.invalidate(allPublicCollaborativeListsProvider);
    _ref.invalidate(allAvailableCollaborativeListsProvider);
    // The list is drawn on its owner's profile too, with a count and a cover
    // that both just moved.
    _invalidateOwnerProfileLists(listId);
    if (mediaType != null) {
      _ref.invalidate(
        collaborativeListsContainingProvider((id: mediaId, type: mediaType)),
      );
    }
    return res;
  }
}
