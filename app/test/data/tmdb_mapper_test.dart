import 'package:cinetrack/data/remote/tmdb/tmdb_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressions for two defects reported from device use.
void main() {
  group('title fallback · fa → en → original', () {
    /// The service returns the Persian translation when one exists, and
    /// otherwise falls back to the *original* language — never English.
    Map<String, dynamic> movie({
      required String delivered,
      String? overview,
      List<Map<String, dynamic>> translations = const [],
    }) => {
      'id': 1,
      'title': delivered,
      'original_title': delivered,
      'overview': overview,
      'translations': {'translations': translations},
    };

    Map<String, dynamic> tr(String lang, String? title, String? overview) => {
      'iso_639_1': lang,
      'data': {'title': title, 'name': title, 'overview': overview},
    };

    test('keeps the Persian title when the service supplied one', () {
      final m = TmdbMapper.movie(
        movie(
          delivered: 'تل‌ماسه',
          overview: 'خلاصه فارسی',
          translations: [
            tr('fa', 'تل‌ماسه', 'خلاصه فارسی'),
            tr('en', 'Dune', 'English'),
          ],
        ),
      );

      expect(m.title, 'تل‌ماسه');
      expect(m.overview, 'خلاصه فارسی');
    });

    test('falls back to English when no Persian translation exists', () {
      // This is the reported bug: a Russian film arrived as "Зеркало" because
      // the delivered title was non-null, just not Persian.
      final m = TmdbMapper.movie(
        movie(
          delivered: 'Зеркало',
          overview: null,
          translations: [
            tr('en', 'Mirror', 'A poetic film.'),
            tr('ru', 'Зеркало', null),
          ],
        ),
      );

      expect(m.title, 'Mirror');
      expect(m.overview, 'A poetic film.');
    });

    test('falls back to English for a Korean film with no Persian entry', () {
      final m = TmdbMapper.movie(
        movie(
          delivered: '기생충',
          translations: [tr('en', 'Parasite', 'A poor family...')],
        ),
      );

      expect(m.title, 'Parasite');
    });

    test('keeps the original when neither Persian nor English exists', () {
      final m = TmdbMapper.movie(
        movie(delivered: '기생충', translations: [tr('ko', '기생충', null)]),
      );

      expect(m.title, '기생충');
    });

    test('works when the response carries no translations at all', () {
      final m = TmdbMapper.movie({
        'id': 1,
        'title': 'Dune',
        'original_title': 'Dune',
      });

      expect(m.title, 'Dune');
    });

    test('a translated title with an untranslated synopsis keeps both', () {
      final m = TmdbMapper.movie(
        movie(
          delivered: 'تل‌ماسه',
          overview: null,
          translations: [
            tr('fa', 'تل‌ماسه', null),
            tr('en', 'Dune', 'English synopsis'),
          ],
        ),
      );

      expect(m.title, 'تل‌ماسه');
      expect(m.overview, 'English synopsis');
    });

    test('series use `name` rather than `title`', () {
      final s = TmdbMapper.series({
        'id': 1,
        'name': '런닝맨',
        'original_name': '런닝맨',
        'translations': {
          'translations': [tr('en', 'Running Man', 'A variety show.')],
        },
      });

      expect(s.name, 'Running Man');
    });
  });

  group('FR-05 · an actor\'s credits are ranked usefully', () {
    Map<String, dynamic> credit({
      required String title,
      required double popularity,
      double vote = 0,
      String? character,
      List<int> genreIds = const [],
      String? job,
    }) => {
      'id': title.hashCode,
      'media_type': 'movie',
      'title': title,
      'popularity': popularity,
      'vote_average': vote,
      'character': character,
      'genre_ids': genreIds,
      'job': job,
    };

    test('popularity decides the order, not a rating from two votes', () {
      // The exact shape of the reported bug: "The Frame" scored 10.0 from two
      // votes and outranked Harry Potter's 7.8 from 22,473.
      final results = TmdbMapper.personCredits({
        'cast': [
          credit(title: 'The Frame', popularity: 1.2, vote: 10),
          credit(title: 'Harry Potter', popularity: 35.2, vote: 7.8),
          credit(title: 'The Batman', popularity: 39.8, vote: 7.6),
        ],
        'crew': const <Map<String, dynamic>>[],
      });

      expect(results.map((r) => r.title), [
        'The Batman',
        'Harry Potter',
        'The Frame',
      ]);
    });

    test('talk shows and reality credits are excluded', () {
      final results = TmdbMapper.personCredits({
        'cast': [
          // Enormously popular, but not part of anyone's filmography.
          credit(title: 'Jimmy Fallon', popularity: 213.5, genreIds: [10767]),
          credit(title: 'Running Man', popularity: 92.8, genreIds: [10764]),
          credit(title: 'Tenet', popularity: 21.7),
        ],
        'crew': const <Map<String, dynamic>>[],
      });

      expect(results.map((r) => r.title), ['Tenet']);
    });

    test('appearances as oneself are excluded', () {
      final results = TmdbMapper.personCredits({
        'cast': [
          credit(title: 'Some Documentary', popularity: 99, character: 'Self'),
          credit(title: 'Another Show', popularity: 98, character: 'Himself'),
          credit(title: 'Tenet', popularity: 21.7, character: 'Neil'),
        ],
        'crew': const <Map<String, dynamic>>[],
      });

      expect(results.map((r) => r.title), ['Tenet']);
    });

    test('crew credits are limited to directing', () {
      final results = TmdbMapper.personCredits({
        'cast': const <Map<String, dynamic>>[],
        'crew': [
          credit(title: 'Directed Film', popularity: 10, job: 'Director'),
          credit(title: 'Produced Film', popularity: 50, job: 'Producer'),
          credit(title: 'Catering Gig', popularity: 90, job: 'Craft Service'),
        ],
      });

      expect(results.map((r) => r.title), ['Directed Film']);
    });

    test('a title credited twice appears once', () {
      final results = TmdbMapper.personCredits({
        'cast': [credit(title: 'Dual Role', popularity: 10)],
        'crew': [credit(title: 'Dual Role', popularity: 10, job: 'Director')],
      });

      expect(results, hasLength(1));
    });
  });
}
