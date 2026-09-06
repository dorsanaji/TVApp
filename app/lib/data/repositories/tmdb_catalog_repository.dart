import 'package:dio/dio.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/credits.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../remote/tmdb/tmdb_api.dart';
import '../remote/tmdb/tmdb_mapper.dart';

/// [CatalogRepository] backed by the information service (§3.1, NM-02).
///
/// Its whole job is to call the API, map the response, and convert anything
/// that goes wrong into a [Failure]. Nothing here throws — FR-20's guarantee
/// that the user always sees a sensible message depends on that being true at
/// every call site, not most of them.
class TmdbCatalogRepository implements CatalogRepository {
  TmdbCatalogRepository(this._api);

  final TmdbApi _api;

  /// Genre names are needed on every detail screen and by the FR-19 statistic.
  /// The list changes perhaps yearly, so it is fetched once per launch —
  /// NM-08 and NFR-42 both argue against re-downloading it.
  List<Genre>? _genreCache;

  /// Runs [body], converting any throw into a [Failure].
  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on DioException catch (e) {
      return Err(ErrorMapper.fromDio(e));
    } catch (e, stack) {
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  // ── FR-05 · Search ────────────────────────────────────────────────────

  @override
  Future<Result<Paged<MediaSummary>>> search(String query, {int page = 1}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Ok(Paged<MediaSummary>.empty()));
    }
    return _guard(() async {
      final json = await _api.searchMulti(trimmed, page: page);
      return TmdbMapper.pagedSummaries(json);
    });
  }

  @override
  Future<Result<Paged<MediaSummary>>> searchByPerson(
    String name, {
    int page = 1,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Ok(Paged<MediaSummary>.empty()));
    }
    return _guard(() async {
      // Two hops: resolve the name to a person, then read their filmography.
      // The service offers no direct "titles by person name" endpoint.
      final people = await _api.searchPerson(trimmed, page: page);
      final results = people['results'];
      if (results is! List || results.isEmpty) {
        return const Paged<MediaSummary>.empty();
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) {
        return const Paged<MediaSummary>.empty();
      }

      final personId = first['id'];
      if (personId is! int) return const Paged<MediaSummary>.empty();

      final credits = await _api.personCredits(personId);
      final items = TmdbMapper.personCredits(credits);

      // The credits endpoint is unpaged, so the whole filmography arrives at
      // once. It is presented as a single page rather than pretending
      // otherwise.
      return Paged(
        items: items,
        page: 1,
        totalPages: 1,
        totalResults: items.length,
      );
    });
  }

  @override
  Future<Result<Paged<MediaSummary>>> discover({
    int? genreId,
    int? year,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  }) {
    return _guard(() async {
      switch (type) {
        case MediaTypeFilter.movie:
          final json = await _api.discoverMovies(
            genreId: genreId,
            year: year,
            page: page,
          );
          return TmdbMapper.pagedSummaries(json, fallbackType: MediaType.movie);

        case MediaTypeFilter.series:
          final json = await _api.discoverSeries(
            genreId: genreId,
            year: year,
            page: page,
          );
          return TmdbMapper.pagedSummaries(
            json,
            fallbackType: MediaType.series,
          );

        case MediaTypeFilter.all:
          // Discovery is type-specific upstream, so both are fetched and
          // interleaved. They run concurrently — sequential awaits here would
          // double the latency for no reason (NFR-02).
          final responses = await Future.wait([
            _api.discoverMovies(genreId: genreId, year: year, page: page),
            _api.discoverSeries(genreId: genreId, year: year, page: page),
          ]);

          final movies = TmdbMapper.pagedSummaries(
            responses[0],
            fallbackType: MediaType.movie,
          );
          final series = TmdbMapper.pagedSummaries(
            responses[1],
            fallbackType: MediaType.series,
          );

          final merged = [
            ...movies.items,
            ...series.items,
          ]..sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));

          return Paged(
            items: merged,
            page: page,
            totalPages: movies.totalPages > series.totalPages
                ? movies.totalPages
                : series.totalPages,
            totalResults: movies.totalResults + series.totalResults,
          );
      }
    });
  }

  // ── FR-06 / FR-07 · Details ───────────────────────────────────────────

  @override
  Future<Result<Movie>> movieDetails(int id) =>
      _guard(() async => TmdbMapper.movie(await _api.movie(id)));

  @override
  Future<Result<Series>> seriesDetails(int id) =>
      _guard(() async => TmdbMapper.series(await _api.series(id)));

  // ── FR-08 · Seasons and episodes ──────────────────────────────────────

  @override
  Future<Result<Season>> season(int seriesId, int seasonNumber) => _guard(
    () async => TmdbMapper.season(await _api.season(seriesId, seasonNumber)),
  );

  // ── FR-18 · Home sections ─────────────────────────────────────────────

  @override
  Future<Result<Paged<MediaSummary>>> popularMovies({int page = 1}) => _guard(
    () async => TmdbMapper.pagedSummaries(
      await _api.popularMovies(page: page),
      fallbackType: MediaType.movie,
    ),
  );

  @override
  Future<Result<Paged<MediaSummary>>> popularSeries({int page = 1}) => _guard(
    () async => TmdbMapper.pagedSummaries(
      await _api.popularSeries(page: page),
      fallbackType: MediaType.series,
    ),
  );

  @override
  Future<Result<Paged<MediaSummary>>> newReleases({int page = 1}) => _guard(
    () async => TmdbMapper.pagedSummaries(
      await _api.nowPlaying(page: page),
      fallbackType: MediaType.movie,
    ),
  );

  @override
  Future<Result<Paged<MediaSummary>>> topRated({int page = 1}) => _guard(
    () async => TmdbMapper.pagedSummaries(
      await _api.topRatedMovies(page: page),
      fallbackType: MediaType.movie,
    ),
  );

  @override
  Future<Result<Paged<MediaSummary>>> recommendations({
    int? forId,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  }) {
    return _guard(() async {
      // With no seed title — a guest, or a user who has not tracked anything
      // yet (§4.1) — trending stands in, so the section is never empty.
      if (forId == null) {
        return TmdbMapper.pagedSummaries(await _api.trending(page: page));
      }

      final json = await _api.recommendations(
        forId,
        isMovie: type != MediaTypeFilter.series,
        page: page,
      );
      final recommended = TmdbMapper.pagedSummaries(
        json,
        fallbackType: type == MediaTypeFilter.series
            ? MediaType.series
            : MediaType.movie,
      );

      // A niche or very new title can have no recommendations at all; falling
      // back keeps the home screen's fifth section populated (FR-18).
      if (recommended.isEmpty) {
        return TmdbMapper.pagedSummaries(await _api.trending(page: page));
      }
      return recommended;
    });
  }

  // ── Genres ────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Genre>>> genres() {
    final cached = _genreCache;
    if (cached != null) return Future.value(Ok(cached));

    return _guard(() async {
      final responses = await Future.wait([
        _api.movieGenres(),
        _api.seriesGenres(),
      ]);

      // Film and series genre lists overlap heavily; Genre's identity is its
      // id, so a set de-duplicates them.
      final combined = <Genre>{
        ...TmdbMapper.genres(responses[0]['genres']),
        ...TmdbMapper.genres(responses[1]['genres']),
      }.toList()..sort((a, b) => a.name.compareTo(b.name));

      _genreCache = combined;
      return combined;
    });
  }
}
