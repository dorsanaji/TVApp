/// The type of social activity recorded (Task 1).
enum SocialActionType {
  reviewed('reviewed'),
  addedToList('added_to_list'),
  watched('watched');

  const SocialActionType(this.value);
  final String value;

  static SocialActionType fromString(String raw) => switch (raw) {
    'reviewed' => SocialActionType.reviewed,
    'added_to_list' => SocialActionType.addedToList,
    'watched' => SocialActionType.watched,
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

  // Metadata for rich activity feed presentation without extra network calls
  final String? username;
  final String? userAvatar;
  final String? movieTitle;
  final String? moviePoster;
  final double? rating;
  final String? reviewText;
  final String? listTitle;

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
    };
  }

  SocialActivity copyWith({
    String? activityId,
    String? userId,
    SocialActionType? actionType,
    int? movieId,
    DateTime? timestamp,
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
