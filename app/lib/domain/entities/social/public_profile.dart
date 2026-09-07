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

  /// Up to [maxFavouriteGenres] genres the user chose, stored comma-separated
  /// because `public_profiles` has one text column for them.
  ///
  /// Previously this was a single genre computed from watch history. It is
  /// the user's own answer now — what someone says they like is a better
  /// profile than what a counter infers.
  final String? favoriteGenre;

  /// How many genres a user may pick.
  static const int maxFavouriteGenres = 3;

  /// [favoriteGenre] split into its parts.
  List<String> get favoriteGenres {
    final raw = favoriteGenre?.trim();
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .take(maxFavouriteGenres)
        .toList();
  }

  /// Joins [genres] into the stored form, or null when empty.
  static String? joinGenres(Iterable<String> genres) {
    final cleaned = genres
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .take(maxFavouriteGenres)
        .toList();
    return cleaned.isEmpty ? null : cleaned.join(', ');
  }
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
    bool clearFavoriteGenre = false,
  }) {
    return PublicProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      totalWatched: totalWatched ?? this.totalWatched,
      // `??` cannot express "set it back to nothing", which clearing every
      // chosen genre has to do.
      favoriteGenre:
          clearFavoriteGenre ? null : (favoriteGenre ?? this.favoriteGenre),
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
