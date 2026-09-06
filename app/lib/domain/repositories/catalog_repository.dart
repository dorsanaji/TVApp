import '../../core/error/result.dart';
import '../entities/credits.dart';
import '../entities/episode.dart';
import '../entities/media_summary.dart';
import '../entities/movie.dart';
import '../entities/series.dart';

/// Read access to the film and series catalogue.
///
/// **This interface is the architectural seam.** The presentation layer
/// depends on this abstraction and never on `TmdbCatalogRepository`, the
/// concrete implementation that calls the information service.
///
/// That is what satisfies NFR-32 (interface logic, data retrieval, and storage
/// separated from one another) and NFR-33 (the project structure must allow
/// changing the API or the information service): replacing the data source
/// means writing one new class and changing one line in the composition root,
/// with no change to any screen, use case, or test.
///
/// Implementations must not throw: every outcome is a [Result].
abstract interface class CatalogRepository {
  // ── FR-05 · Search ────────────────────────────────────────────────────

  /// Combined film + series search by title. The minimum the brief requires.
  Future<Result<Paged<MediaSummary>>> search(String query, {int page = 1});

  /// FR-05 optional criteria: by performer or director name.
  Future<Result<Paged<MediaSummary>>> searchByPerson(
    String name, {
    int page = 1,
  });

  /// FR-05 optional criteria: by genre and/or release year.
  Future<Result<Paged<MediaSummary>>> discover({
    int? genreId,
    int? year,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  });

  // ── FR-06 / FR-07 · Details ───────────────────────────────────────────

  Future<Result<Movie>> movieDetails(int id);

  Future<Result<Series>> seriesDetails(int id);

  // ── FR-08 · Seasons and episodes ──────────────────────────────────────

  /// One season with its episodes. Fetched per season rather than eagerly for
  /// the whole series, per NFR-04.
  Future<Result<Season>> season(int seriesId, int seasonNumber);

  // ── FR-18 · Home screen sections ──────────────────────────────────────

  Future<Result<Paged<MediaSummary>>> popularMovies({int page = 1});
  Future<Result<Paged<MediaSummary>>> popularSeries({int page = 1});

  /// "آثار جدید" — recent releases.
  Future<Result<Paged<MediaSummary>>> newReleases({int page = 1});

  /// "آثار دارای امتیاز بالا".
  Future<Result<Paged<MediaSummary>>> topRated({int page = 1});

  /// "فیلم‌ها و سریال‌های پیشنهادی". Personalised when a title is supplied;
  /// falls back to trending for a guest with no history (§4.1).
  Future<Result<Paged<MediaSummary>>> recommendations({
    int? forId,
    MediaTypeFilter type = MediaTypeFilter.all,
    int page = 1,
  });

  /// Genre lookup, used by the FR-05 filter and the FR-19 favourite-genre
  /// statistic.
  Future<Result<List<Genre>>> genres();
}

/// Narrows a query to one media type.
enum MediaTypeFilter { all, movie, series }
