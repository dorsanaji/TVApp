import '../../../domain/entities/enums.dart';
import '../../../domain/entities/social/custom_list.dart';
import '../../../domain/entities/social/custom_list_item.dart';
import '../../../domain/entities/social/list_collaborator.dart';
import '../../../domain/entities/social/public_profile.dart';
import '../../../domain/entities/social/social_activity.dart';

/// Maps raw Supabase json/records to and from Domain entities.
abstract final class SupabaseMapper {
  const SupabaseMapper._();

  // ── PublicProfile ─────────────────────────────────────────────────────

  static PublicProfile profileFromMap(
    Map<String, dynamic> map, {
    int followers = 0,
    int following = 0,
    bool isFollowing = false,
  }) {
    return PublicProfile(
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      totalWatched: (map['total_watched'] as num?)?.toInt() ?? 0,
      favoriteGenre: map['favorite_genre'] as String?,
      followersCount: followers,
      followingCount: following,
      isFollowing: isFollowing,
    );
  }

  static Map<String, dynamic> profileToMap(PublicProfile profile) {
    return {
      'user_id': profile.userId,
      'username': profile.username,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'total_watched': profile.totalWatched,
      'favorite_genre': profile.favoriteGenre,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ── CustomList ────────────────────────────────────────────────────────

  static CustomList customListFromMap(
    Map<String, dynamic> map, {
    int collaboratorCount = 0,
  }) {
    return CustomList(
      listId: map['list_id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      isPublic: map['is_public'] as bool? ?? true,
      coverPath: map['cover_path'] as String?,
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      collaboratorCount: collaboratorCount,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> customListToMap(CustomList list) {
    return {
      'list_id': list.listId,
      'owner_id': list.ownerId,
      'title': list.title,
      'description': list.description,
      'is_public': list.isPublic,
      'cover_path': list.coverPath,
      'item_count': list.itemCount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ── ListCollaborator ──────────────────────────────────────────────────

  static ListCollaborator collaboratorFromMap(Map<String, dynamic> map) {
    return ListCollaborator(
      listId: map['list_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      addedAt: DateTime.tryParse(map['added_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> collaboratorToMap(ListCollaborator collaborator) {
    return {
      'list_id': collaborator.listId,
      'user_id': collaborator.userId,
      'username': collaborator.username,
      'avatar_url': collaborator.avatarUrl,
      'added_at': (collaborator.addedAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
    };
  }

  // ── CustomListItem ────────────────────────────────────────────────────

  static CustomListItem listItemFromMap(Map<String, dynamic> map) {
    return CustomListItem(
      id: map['id'] as String? ?? '',
      listId: map['list_id'] as String? ?? '',
      mediaId: (map['media_id'] as num?)?.toInt() ?? 0,
      mediaType: (map['media_type'] as String?) == 'series'
          ? MediaType.series
          : MediaType.movie,
      title: map['title'] as String? ?? '',
      posterPath: map['poster_path'] as String?,
      overview: map['overview'] as String?,
      releaseDate: map['release_date'] as String?,
      voteAverage: (map['vote_average'] as num?)?.toDouble(),
      addedBy: map['added_by'] as String?,
      addedAt: DateTime.tryParse(map['added_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> listItemToMap(CustomListItem item) {
    return {
      'id': item.id,
      'list_id': item.listId,
      'media_id': item.mediaId,
      'media_type': item.mediaType.name,
      'title': item.title,
      'poster_path': item.posterPath,
      'overview': item.overview,
      'release_date': item.releaseDate,
      'vote_average': item.voteAverage,
      'added_by': item.addedBy,
      'added_at': (item.addedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  // ── SocialActivity ────────────────────────────────────────────────────

  static SocialActivity activityFromMap(Map<String, dynamic> map) {
    final activityId = map['activity_id'] as String? ?? '';
    return SocialActivity(
      activityId: activityId,
      mediaType: SocialActivity.mediaTypeOf(activityId),
      userId: map['user_id'] as String? ?? '',
      actionType: SocialActionType.fromString(
        map['action_type'] as String? ?? 'watched',
      ),
      movieId: (map['movie_id'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      movieTitle: map['movie_title'] as String?,
      moviePoster: map['movie_poster'] as String?,
      username: map['username'] as String?,
      userAvatar: map['user_avatar'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['review_text'] as String?,
      listTitle: map['list_title'] as String?,
    );
  }

  static Map<String, dynamic> activityToMap(SocialActivity activity) {
    return {
      'activity_id': activity.activityId,
      'user_id': activity.userId,
      'action_type': activity.actionType.value,
      'movie_id': activity.movieId,
      'movie_title': activity.movieTitle,
      'movie_poster': activity.moviePoster,
      'username': activity.username,
      'user_avatar': activity.userAvatar,
      'rating': activity.rating,
      'review_text': activity.reviewText,
      'list_title': activity.listTitle,
      'created_at': activity.timestamp.toUtc().toIso8601String(),
    };
  }
}
