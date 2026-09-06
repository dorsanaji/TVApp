/// Domain entity for a user's public profile (Task 1).
///
/// Clean Architecture: independent of database and UI frameworks.
class PublicProfile {
  const PublicProfile({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.totalWatched = 0,
    this.favoriteGenre,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int totalWatched;
  final String? favoriteGenre;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  PublicProfile copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    String? bio,
    int? totalWatched,
    String? favoriteGenre,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return PublicProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      totalWatched: totalWatched ?? this.totalWatched,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username &&
          avatarUrl == other.avatarUrl &&
          bio == other.bio &&
          totalWatched == other.totalWatched &&
          favoriteGenre == other.favoriteGenre &&
          followersCount == other.followersCount &&
          followingCount == other.followingCount &&
          isFollowing == other.isFollowing;

  @override
  int get hashCode => Object.hash(
    userId,
    username,
    avatarUrl,
    bio,
    totalWatched,
    favoriteGenre,
    followersCount,
    followingCount,
    isFollowing,
  );
}
