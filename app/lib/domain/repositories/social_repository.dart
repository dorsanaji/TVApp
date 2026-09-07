import '../../core/error/result.dart';
import '../entities/enums.dart';
import '../entities/media_summary.dart';
import '../entities/social/collaboration_request.dart';
import '../entities/social/custom_list.dart';
import '../entities/social/custom_list_item.dart';
import '../entities/social/list_collaborator.dart';
import '../entities/social/public_profile.dart';
import '../entities/social/social_activity.dart';

/// Repository interface for social, collaborative, and activity feed features (Task 1).
///
/// Follows Clean Architecture: domain layer defines contracts without BaaS dependencies.
abstract interface class SocialRepository {
  // ── PublicProfile (CRUD & Following) ──────────────────────────────────

  /// Fetches a user's public social profile by their user ID.
  Future<Result<PublicProfile>> getProfile(String userId);

  /// Creates or updates a public social profile.
  Future<Result<PublicProfile>> upsertProfile(PublicProfile profile);

  /// Follows a target user.
  Future<Result<void>> followUser({
    required String followerId,
    required String followedId,
  });

  /// Unfollows a target user.
  Future<Result<void>> unfollowUser({
    required String followerId,
    required String followedId,
  });

  /// Checks if [followerId] is following [followedId].
  Future<Result<bool>> isFollowing({
    required String followerId,
    required String followedId,
  });

  /// Returns the list of user IDs that [userId] follows.
  Future<Result<List<String>>> getFollowedUserIds(String userId);

  /// The other direction: who follows [userId].
  Future<Result<List<String>>> getFollowerUserIds(String userId);

  /// Searches for users by username, display name, or returns suggested users when query is empty.
  Future<Result<List<PublicProfile>>> searchUsers(String query);

  // ── CustomList (CRUD & Real-time Streams) ──────────────────────────────

  /// Creates a new collaborative or public custom list.
  Future<Result<CustomList>> createList({
    required String ownerId,
    required String title,
    String? description,
    bool isPublic = true,
  });

  /// Fetches a single CustomList by ID.
  Future<Result<CustomList>> getList(String listId);

  /// Returns all public lists created by [userId].
  Future<Result<List<CustomList>>> getPublicListsOfUser(String userId);

  /// Returns all lists accessible to [userId] (owned or collaborated).
  Future<Result<List<CustomList>>> getUserAccessibleLists(String userId);

  /// Returns all public collaborative lists in the system.
  Future<Result<List<CustomList>>> getAllPublicLists();

  /// Returns the set of collaborative list IDs that contain the given media item.
  Future<Result<Set<String>>> getCollaborativeListIdsContaining({
    required int mediaId,
    required MediaType mediaType,
  });

  /// Updates an existing CustomList.
  Future<Result<CustomList>> updateList(CustomList list);

  /// Deletes a CustomList by ID.
  Future<Result<void>> deleteList(String listId);

  /// Real-time stream of a CustomList's details.
  Stream<CustomList?> watchList(String listId);

  // ── ListCollaborator (CRUD & Real-time Streams) ────────────────────────

  /// Adds a collaborator to a CustomList.
  Future<Result<void>> addCollaborator({
    required String listId,
    required String userId,
  });

  /// Removes a collaborator from a CustomList.
  Future<Result<void>> removeCollaborator({
    required String listId,
    required String userId,
  });

  /// Returns all collaborators for a given list.
  Future<Result<List<ListCollaborator>>> getCollaborators(String listId);

  /// Returns true if [userId] is an owner or collaborator of [listId].
  Future<Result<bool>> isCollaborator({
    required String listId,
    required String userId,
  });

  /// Real-time stream of collaborators for a list.
  Stream<List<ListCollaborator>> watchCollaborators(String listId);

  // ── Collaboration Access Requests ─────────────────────────────────────

  /// Submits an access request to collaborate on [listId].
  Future<Result<void>> requestCollaboratorAccess({
    required String listId,
    required String userId,
  });

  /// Cancels a pending access request for [listId] submitted by [userId].
  Future<Result<void>> cancelCollaboratorRequest({
    required String listId,
    required String userId,
  });

  /// Approves a collaborator access request, officially adding them to [listId].
  Future<Result<void>> acceptCollaboratorRequest({
    required String listId,
    required String userId,
  });

  /// Rejects/declines a collaborator access request for [listId].
  Future<Result<void>> rejectCollaboratorRequest({
    required String listId,
    required String userId,
  });

  /// Returns pending access requests for [listId].
  Future<Result<List<CollaborationRequest>>> getCollaborationRequests(String listId);

  /// Real-time stream of pending access requests for [listId].
  Stream<List<CollaborationRequest>> watchCollaborationRequests(String listId);

  // ── Collaborative List Items ──────────────────────────────────────────

  /// Adds a film or series to a collaborative CustomList.
  Future<Result<void>> addMovieToList({
    required String listId,
    required MediaSummary item,
    required String addedByUserId,
  });

  /// Removes a film or series from a collaborative CustomList.
  Future<Result<void>> removeMovieFromList({
    required String listId,
    required int mediaId,
  });

  /// Returns items in a CustomList.
  Future<Result<List<CustomListItem>>> getListItems(String listId);

  /// Real-time stream of items in a CustomList.
  Stream<List<CustomListItem>> watchListItems(String listId);

  // ── SocialActivity (Feed & Real-time Streams) ──────────────────────────

  /// Logs a new social activity (e.g. reviewed, added_to_list, watched).
  Future<Result<void>> logActivity(SocialActivity activity);

  /// Removes a previously logged activity, for actions that can be undone —
  /// un-favouriting, unfollowing.
  Future<Result<void>> deleteActivity(String activityId);

  /// Fetches recent activities from users followed by [userIds].
  Future<Result<List<SocialActivity>>> getActivityFeed({
    required List<String> userIds,
    int limit = 30,
  });

  /// Fetches activities performed by a specific user.
  Future<Result<List<SocialActivity>>> getUserActivities(
    String userId, {
    int limit = 30,
  });

  /// Real-time stream of activity feed for the specified followed users.
  Stream<List<SocialActivity>> watchActivityFeed(List<String> userIds);
}
