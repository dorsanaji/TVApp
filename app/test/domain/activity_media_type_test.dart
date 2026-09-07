import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/public_profile.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('media type on an activity', () {
    test('round-trips through the activity id', () {
      final id = SocialActivity.buildId(
        prefix: 'fav',
        userId: 'user_123',
        mediaType: MediaType.series,
        mediaId: 113962,
      );

      expect(id, 'fav_user_123_series_113962');
      expect(SocialActivity.mediaTypeOf(id), MediaType.series);
    });

    test('carries a suffix without losing the type', () {
      final id = SocialActivity.buildId(
        prefix: 'add',
        userId: 'user_123',
        mediaType: MediaType.movie,
        mediaId: 550,
        suffix: 'list_9',
      );

      expect(SocialActivity.mediaTypeOf(id), MediaType.movie);
    });

    test('ids written before the type was recorded read as null', () {
      // The old format, which is why the fallback has to be the film route.
      expect(SocialActivity.mediaTypeOf('watch_user_123_5920'), isNull);
    });
  });

  group('favourite genres', () {
    test('are stored and read back as a list', () {
      const profile = PublicProfile(
        userId: 'u',
        username: 'n',
        favoriteGenre: 'درام, کمدی, ترسناک',
      );

      expect(profile.favoriteGenres, ['درام', 'کمدی', 'ترسناک']);
    });

    test('are capped at three', () {
      final joined = PublicProfile.joinGenres(
        ['درام', 'کمدی', 'ترسناک', 'وسترن'],
      );

      expect(joined, 'درام, کمدی, ترسناک');
      expect(
        PublicProfile(userId: 'u', username: 'n', favoriteGenre: joined)
            .favoriteGenres,
        hasLength(PublicProfile.maxFavouriteGenres),
      );
    });

    test('no genres reads as empty, not as a blank entry', () {
      const none = PublicProfile(userId: 'u', username: 'n');
      const blank =
          PublicProfile(userId: 'u', username: 'n', favoriteGenre: '  ');

      expect(none.favoriteGenres, isEmpty);
      expect(blank.favoriteGenres, isEmpty);
      expect(PublicProfile.joinGenres(const []), isNull);
    });

    test('clearing every genre wipes the stored value', () {
      const profile = PublicProfile(
        userId: 'u',
        username: 'n',
        favoriteGenre: 'درام',
      );

      expect(profile.copyWith(clearFavoriteGenre: true).favoriteGenre, isNull);
    });
  });
}
