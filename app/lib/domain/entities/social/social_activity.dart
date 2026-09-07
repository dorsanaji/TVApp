import '../enums.dart';

/// The type of social activity recorded (Task 1).
enum SocialActionType {
  reviewed('reviewed'),
  addedToList('added_to_list'),
  watched('watched'),

  /// FR-16's heart. Recorded so a profile can show what its owner loves —
  /// the favourites table itself is on the user's own device, so without
  /// this nobody else could ever see it.
  favourited('favourited'),

  /// One user following another.
  followed('followed'),

  /// A private watch-diary entry: a date, a rating, and what the user
  /// thought.
  ///
  /// Kept apart from [reviewed] on purpose. A review is published under the
  /// title for everyone who opens it and travels to friends' feeds; a diary
  /// entry does neither. It is a personal log that shows only in its owner's
  /// profile, so writing one must never put words under a film.
  diary('diary');

  const SocialActionType(this.value);
  final String value;

  static SocialActionType fromString(String raw) => switch (raw) {
    'reviewed' => SocialActionType.reviewed,
    'added_to_list' => SocialActionType.addedToList,
    'watched' => SocialActionType.watched,
    'favourited' => SocialActionType.favourited,
    'followed' => SocialActionType.followed,
    'diary' => SocialActionType.diary,
    _ => SocialActionType.watched,
  };
}

/// Domain entity for Letterboxd-style social activity (Task 1).
///
/// Clean Architecture: independent of database and UI frameworks.
class SocialActivity {
  const SocialActivity({
    required this.activityId,
    required this.userId,
    required this.actionType,
    required this.movieId,
    required this.timestamp,
    this.mediaType,
    this.username,
    this.userAvatar,
    this.movieTitle,
    this.moviePoster,
    this.rating,
    this.reviewText,
    this.listTitle,
  });

  final String activityId;
  final String userId;
  final SocialActionType actionType;
  final int movieId;
  final DateTime timestamp;

  /// Whether [movieId] is a film or a series.
  ///
  /// `social_activities` has no column for it, so it rides in the activity
  /// id (see [mediaTypeOf]). Null for rows written before that, which are
  /// read as films — the id space is shared, so without this a favourited
  /// series opened the film with the same number.
  final MediaType? mediaType;

  // Metadata for rich activity feed presentation without extra network calls
  final String? username;
  final String? userAvatar;
  final String? movieTitle;
  final String? moviePoster;
  final double? rating;
  final String? reviewText;
  final String? listTitle;

  /// Builds an activity id that carries the media type.
  ///
  /// Films and series share TMDB's id space, and the activity table has no
  /// column to tell them apart, so the type is written into the key itself:
  /// `fav_<user>_series_113962`. [mediaTypeOf] reads it back.
  static String buildId({
    required String prefix,
    required String userId,
    required MediaType mediaType,
    required int mediaId,
    String? suffix,
  }) {
    final base = '${prefix}_${userId}_${mediaType.name}_$mediaId';
    return suffix == null ? base : '${base}_$suffix';
  }

  /// The media type encoded in [activityId], or null for older ids that
  /// predate the encoding.
  static MediaType? mediaTypeOf(String activityId) {
    final parts = activityId.split('_');
    for (final type in MediaType.values) {
      if (parts.contains(type.name)) return type;
    }
    return null;
  }

  /// Human-readable Persian summary of the activity.
  String toPersianSentence() {
    final actor = username ?? 'کاربر';
    final movie = movieTitle ?? 'فیلم';

    return switch (actionType) {
      SocialActionType.reviewed =>
        rating != null
            ? '$actor فیلم «$movie» را نقد کرد و به آن $rating ستاره داد'
            : '$actor فیلم «$movie» را نقد کرد',
      SocialActionType.watched => '$actor فیلم «$movie» را تماشا کرد',
      SocialActionType.addedToList =>
        listTitle != null
            ? '$actor فیلم «$movie» را به فهرست «$listTitle» افزود'
            : '$actor فیلم «$movie» را به فهرست افزود',
      SocialActionType.favourited => '$actor «$movie» را به موردعلاقه‌ها افزود',
      SocialActionType.diary => rating != null
          ? '«$movie» — ${rating!.toStringAsFixed(1)} ستاره'
          : '«$movie»',
      // The followed user's name is carried in `movieTitle`, which is the
      // only free text column the activity row has.
      SocialActionType.followed => '$actor «$movie» را دنبال کرد',
    };
  }

  SocialActivity copyWith({
    String? activityId,
    String? userId,
    SocialActionType? actionType,
    int? movieId,
    DateTime? timestamp,
    MediaType? mediaType,
    String? username,
    String? userAvatar,
    String? movieTitle,
    String? moviePoster,
    double? rating,
    String? reviewText,
    String? listTitle,
  }) {
    return SocialActivity(
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      movieId: movieId ?? this.movieId,
      timestamp: timestamp ?? this.timestamp,
      mediaType: mediaType ?? this.mediaType,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      movieTitle: movieTitle ?? this.movieTitle,
      moviePoster: moviePoster ?? this.moviePoster,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      listTitle: listTitle ?? this.listTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialActivity &&
          runtimeType == other.runtimeType &&
          activityId == other.activityId;

  @override
  int get hashCode => activityId.hashCode;
}
