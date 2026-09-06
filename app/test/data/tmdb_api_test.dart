import 'dart:typed_data';

import 'package:cinetrack/data/remote/tmdb/tmdb_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for a defect that shipped to the device: every detail request
/// went to the literal path `/movie/$id` instead of `/movie/438631`, because
/// the Dart source contained an *escaped* dollar (`'\$id'`). The service
/// answered 404 and the app showed «فیلم یا سریال موردنظر پیدا نشد» for every
/// title.
///
/// Nothing caught it — `flutter analyze` was clean and 146 tests passed —
/// because no test exercised URL construction. These do.
void main() {
  late Dio dio;
  late TmdbApi api;
  late List<String> requested;

  setUp(() {
    requested = [];
    dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'));
    dio.httpClientAdapter = _RecordingAdapter(requested);
    api = TmdbApi(dio);
  });

  group('paths interpolate their arguments', () {
    test('movie detail', () async {
      await api.movie(438631);

      expect(requested.single, startsWith('/movie/438631'));
      expect(requested.single, isNot(contains(r'$')));
    });

    test('series detail', () async {
      await api.series(1396);

      expect(requested.single, startsWith('/tv/1396'));
      expect(requested.single, isNot(contains(r'$')));
    });

    test('season', () async {
      await api.season(1396, 2);

      expect(requested.single, '/tv/1396/season/2');
    });

    test('person credits', () async {
      await api.personCredits(11288);

      expect(requested.single, '/person/11288/combined_credits');
    });

    test(
      'recommendations pick the right resource for each media type',
      () async {
        await api.recommendations(1, isMovie: true);
        await api.recommendations(2, isMovie: false);

        expect(requested[0], startsWith('/movie/1/recommendations'));
        expect(requested[1], startsWith('/tv/2/recommendations'));
      },
    );
  });

  test('no endpoint path contains an un-interpolated placeholder', () async {
    await api.movie(1);
    await api.series(2);
    await api.season(3, 4);
    await api.personCredits(5);
    await api.searchMulti('dune');
    await api.popularMovies();
    await api.movieGenres();

    for (final path in requested) {
      expect(
        path,
        isNot(contains(r'$')),
        reason: '$path still holds a literal placeholder',
      );
    }
  });

  test(
    'detail requests ask for translations, credits and external ids',
    () async {
      // The fa → en → original title fallback depends on `translations` riding
      // along here; dropping it would silently regress FR-06/FR-07 titles.
      await api.movie(438631);

      expect(requested.single, contains('append_to_response'));
      expect(requested.single, contains('translations'));
      expect(requested.single, contains('credits'));
      expect(requested.single, contains('external_ids'));
    },
  );
}

/// Captures the path (plus query) of every request instead of sending it.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.requested);

  final List<String> requested;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    requested.add(query.isEmpty ? options.path : '${options.path}?$query');

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
