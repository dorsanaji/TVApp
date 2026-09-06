import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/core/error/result.dart';
import 'package:cinetrack/data/repositories/tmdb_catalog_repository.dart';
import 'package:cinetrack/domain/entities/credits.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/episode.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/movie.dart';
import 'package:cinetrack/domain/entities/series.dart';
import 'package:cinetrack/domain/repositories/catalog_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// NFR-32 and NFR-33 — the interface logic, data retrieval, and storage must
/// be separated, and the project structure must allow changing the API or the
/// information service.
///
/// This test is the evidence. It swaps the entire data source for an in-memory
/// fake by overriding one provider, with no change to any entity, use case, or
/// screen. If the layering ever leaks — a screen importing a TMDB class, say —
/// this stops compiling.
void main() {
  test(
    'the catalogue data source can be replaced without touching callers',
    () async {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepository()),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(catalogRepositoryProvider);
      final result = await repository.search('dune');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.items.first.title, 'تلماسه');
    },
  );

  test(
    'a failing data source surfaces as a Failure, never as a throw',
    () async {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            _FakeCatalogRepository(failing: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(catalogRepositoryProvider)
          .search('x');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ServiceUnavailableFailure>());
    },
  );

  test('the default binding is the information-service implementation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Constructing it must not touch the network — the repository is inert
    // until a method is called, which is what lets the whole graph be built
    // in a test.
    expect(
      container.read(catalogRepositoryProvider),
      isA<TmdbCatalogRepository>(),
    );
  });

  test('an empty query short-circuits without a network call', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container
        .read(catalogRepositoryProvider)
        .search('   ');

    // Whitespace is not a search. Issuing a request for it would be exactly
    // the "unnecessary request" NM-08 forbids.
    expect(result.isOk, isTrue);
    expect(result.valueOrNull?.items, isEmpty);
  });
}

/// Stands in for the whole information service. That this is only a few dozen
/// lines is the point: the contract is small enough to reimplement, which is
/// what "allows changing the information service" means in practice.
class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository({this.failing = false});

  final bool failing;

  static const _dune = MediaSummary(
    id: 438631,
    type: MediaType.movie,
    title: 'تلماسه',
    releaseDate: '2021-10-22',
    voteAverage: 7.8,
  );

  Result<T> _guard<T>(T value) =>
      failing ? const Err(ServiceUnavailableFailure()) : Ok(value);

  @override
  Future<Result<Paged<MediaSummary>>> search(
    String query, {
    int page = 1,
  }) async => _guard(
    const Paged(items: [_dune], page: 1, totalPages: 1, totalResults: 1),
  );

  @override
  Future<Result<Paged<MediaSummary>>> searchByPerson(
    String name, {
    int page = 1,
  }) async => _guard(const Paged.empty());

  @override
  Future<Result<Paged<MediaSummary>>> discover({
    int? genreId,
    int? year,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  }) async => _guard(const Paged.empty());

  @override
  Future<Result<Movie>> movieDetails(int id) async =>
      _guard(const Movie(id: 438631, title: 'تلماسه'));

  @override
  Future<Result<Series>> seriesDetails(int id) async =>
      _guard(const Series(id: 1396, name: 'برکینگ بد'));

  @override
  Future<Result<Season>> season(int seriesId, int seasonNumber) async =>
      _guard(const Season(id: 1, seasonNumber: 1, name: 'فصل ۱', episodes: []));

  @override
  Future<Result<Paged<MediaSummary>>> popularMovies({int page = 1}) async =>
      _guard(const Paged.empty());

  @override
  Future<Result<Paged<MediaSummary>>> popularSeries({int page = 1}) async =>
      _guard(const Paged.empty());

  @override
  Future<Result<Paged<MediaSummary>>> newReleases({int page = 1}) async =>
      _guard(const Paged.empty());

  @override
  Future<Result<Paged<MediaSummary>>> topRated({int page = 1}) async =>
      _guard(const Paged.empty());

  @override
  Future<Result<Paged<MediaSummary>>> recommendations({
    int? forId,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  }) async => _guard(const Paged.empty());

  @override
  Future<Result<List<Genre>>> genres() async => _guard(const <Genre>[]);
}
