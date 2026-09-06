import 'package:dio/dio.dart';

/// Thin HTTP wrapper over the information service.
///
/// Deliberately dumb: it issues requests and returns decoded JSON, nothing
/// more. Interpretation belongs to the mapper and failure handling to the
/// repository, so each piece stays testable on its own (NFR-30, NFR-32).
///
/// NM-02 — film and series information is received directly from the service.
class TmdbApi {
  const TmdbApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return response.data ?? const {};
  }

  // ── FR-05 · Search ────────────────────────────────────────────────────

  /// Films and series in one call, which is what the brief asks for: search
  /// "by the title of the work", not by title within a chosen type.
  Future<Map<String, dynamic>> searchMulti(String query, {int page = 1}) =>
      _get('/search/multi', {
        'query': query,
        'page': page,
        'include_adult': false,
      });

  Future<Map<String, dynamic>> searchPerson(String query, {int page = 1}) =>
      _get('/search/person', {
        'query': query,
        'page': page,
        'include_adult': false,
      });

  /// Everything a performer or director worked on — this is how FR-05's
  /// "by actor name" and "by director name" criteria are served.
  Future<Map<String, dynamic>> personCredits(int personId) =>
      _get('/person/$personId/combined_credits');

  Future<Map<String, dynamic>> discoverMovies({
    int? genreId,
    int? year,
    int page = 1,
  }) => _get('/discover/movie', {
    'page': page,
    'sort_by': 'popularity.desc',
    'with_genres': ?genreId,
    'primary_release_year': ?year,
  });

  Future<Map<String, dynamic>> discoverSeries({
    int? genreId,
    int? year,
    int page = 1,
  }) => _get('/discover/tv', {
    'page': page,
    'sort_by': 'popularity.desc',
    'with_genres': ?genreId,
    'first_air_date_year': ?year,
  });

  // ── FR-06 / FR-07 · Details ───────────────────────────────────────────

  /// `append_to_response` folds credits and the IMDb id into the same request.
  /// Three round trips would otherwise be needed per detail screen, which
  /// NM-08 and NFR-01 both argue against.
  Future<Map<String, dynamic>> movie(int id) => _get('/movie/$id', {
    'append_to_response': 'credits,external_ids,translations',
  });

  Future<Map<String, dynamic>> series(int id) => _get('/tv/$id', {
    'append_to_response': 'credits,external_ids,translations',
  });

  // ── FR-08 · Seasons and episodes ──────────────────────────────────────

  /// One season at a time (NFR-04 — lazy loading). Fetching every season of a
  /// long-running series up front would be dozens of requests for data the
  /// user may never scroll to.
  Future<Map<String, dynamic>> season(int seriesId, int seasonNumber) =>
      _get('/tv/$seriesId/season/$seasonNumber');

  // ── FR-18 · Home sections ─────────────────────────────────────────────

  Future<Map<String, dynamic>> popularMovies({int page = 1}) =>
      _get('/movie/popular', {'page': page});

  Future<Map<String, dynamic>> popularSeries({int page = 1}) =>
      _get('/tv/popular', {'page': page});

  /// "آثار جدید" — currently in cinemas, the closest the service offers to
  /// "new works".
  Future<Map<String, dynamic>> nowPlaying({int page = 1}) =>
      _get('/movie/now_playing', {'page': page});

  Future<Map<String, dynamic>> topRatedMovies({int page = 1}) =>
      _get('/movie/top_rated', {'page': page});

  /// Personalised suggestions, seeded from a title the user has engaged with.
  Future<Map<String, dynamic>> recommendations(
    int id, {
    required bool isMovie,
    int page = 1,
  }) =>
      _get('/${isMovie ? 'movie' : 'tv'}/$id/recommendations', {'page': page});

  /// Fallback for a guest with no history (§4.1).
  Future<Map<String, dynamic>> trending({int page = 1}) =>
      _get('/trending/all/week', {'page': page});

  // ── Genres ────────────────────────────────────────────────────────────

  // Requested in English on purpose: the service returns `name: null` for
  // every genre under `fa-IR`, which previously left the genre filter with no
  // chips at all. Persian names are supplied by `TmdbLocalization`; the
  // English one survives only as a fallback for an id we have not mapped.
  Future<Map<String, dynamic>> movieGenres() =>
      _get('/genre/movie/list', {'language': 'en-US'});

  Future<Map<String, dynamic>> seriesGenres() =>
      _get('/genre/tv/list', {'language': 'en-US'});
}
