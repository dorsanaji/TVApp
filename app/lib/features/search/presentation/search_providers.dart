import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/credits.dart';
import '../../../domain/entities/media_summary.dart';

/// The criteria FR-05 §5.5 lists. Title is the minimum the brief requires;
/// the rest are the "if the information service supports it" extensions, all
/// of which TMDB does.
enum SearchMode {
  title('عنوان اثر'),
  person('بازیگر یا کارگردان'),
  filter('ژانر و سال');

  const SearchMode(this.label);

  final String label;
}

/// What the user has asked for. Immutable, so a stale in-flight response can
/// be recognised and discarded.
class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.mode = SearchMode.title,
    this.genreId,
    this.year,
  });

  final String text;
  final SearchMode mode;
  final int? genreId;
  final int? year;

  bool get isEmpty => switch (mode) {
    SearchMode.title || SearchMode.person => text.trim().isEmpty,
    SearchMode.filter => genreId == null && year == null,
  };

  SearchQuery copyWith({
    String? text,
    SearchMode? mode,
    int? genreId,
    int? year,
    bool clearGenre = false,
    bool clearYear = false,
  }) => SearchQuery(
    text: text ?? this.text,
    mode: mode ?? this.mode,
    genreId: clearGenre ? null : (genreId ?? this.genreId),
    year: clearYear ? null : (year ?? this.year),
  );

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.mode == mode &&
      other.genreId == genreId &&
      other.year == year;

  @override
  int get hashCode => Object.hash(text, mode, genreId, year);
}

/// Holds the query and debounces text input.
///
/// Debouncing is what keeps a five-letter title from becoming five searches.
/// Together with the de-duplication interceptor this is the app-level half of
/// NM-08 and NFR-05.
class SearchQueryNotifier extends StateNotifier<SearchQuery> {
  SearchQueryNotifier() : super(const SearchQuery());

  static const _debounce = Duration(milliseconds: 400);

  Timer? _timer;

  void setText(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) state = state.copyWith(text: text);
    });
  }

  void setMode(SearchMode mode) {
    _timer?.cancel();
    state = state.copyWith(mode: mode);
  }

  void setGenre(int? genreId) => state = genreId == null
      ? state.copyWith(clearGenre: true)
      : state.copyWith(genreId: genreId);

  void setYear(int? year) => state = year == null
      ? state.copyWith(clearYear: true)
      : state.copyWith(year: year);

  void clear() {
    _timer?.cancel();
    state = const SearchQuery();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final searchQueryProvider =
    StateNotifierProvider<SearchQueryNotifier, SearchQuery>((ref) {
      return SearchQueryNotifier();
    });

/// Paged search results (NFR-04 — long lists load gradually).
///
/// Holds the accumulated pages so scrolling appends rather than replacing, and
/// exposes whether more remain so the list knows when to stop asking.
class SearchResults {
  const SearchResults({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<MediaSummary> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  SearchResults copyWith({
    List<MediaSummary>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => SearchResults(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Loads the first page of results for the current query.
///
/// An empty query returns immediately without touching the network — NM-08
/// forbids unnecessary requests, and whitespace is not a search.
final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return const SearchResults();

  final paged = await _fetchPage(ref, query, 1);
  return SearchResults(
    items: paged.items,
    page: paged.page,
    hasMore: paged.hasMore,
  );
});

/// Appends the next page. Exposed separately from [searchResultsProvider] so
/// that loading more does not rebuild — and re-fetch — what is already shown.
final searchPaginationProvider =
    NotifierProvider<SearchPaginationNotifier, SearchResults>(
      SearchPaginationNotifier.new,
    );

class SearchPaginationNotifier extends Notifier<SearchResults> {
  @override
  SearchResults build() {
    // Reset whenever the first page changes, so a new query starts clean
    // rather than appending to the previous one's results.
    final first = ref.watch(searchResultsProvider);
    return first.valueOrNull ?? const SearchResults();
  }

  Future<void> loadMore() async {
    final current = state;
    if (!current.hasMore || current.isLoadingMore) return;

    state = current.copyWith(isLoadingMore: true);

    final query = ref.read(searchQueryProvider);
    try {
      final paged = await _fetchPage(ref, query, current.page + 1);
      state = SearchResults(
        items: [...current.items, ...paged.items],
        page: paged.page,
        hasMore: paged.hasMore,
      );
    } catch (_) {
      // A failed "load more" leaves what is already on screen intact; the
      // user can scroll again to retry.
      state = current.copyWith(isLoadingMore: false);
    }
  }
}

Future<Paged<MediaSummary>> _fetchPage(
  Ref ref,
  SearchQuery query,
  int page,
) async {
  final repository = ref.read(catalogRepositoryProvider);

  final result = switch (query.mode) {
    SearchMode.title => await repository.search(query.text, page: page),
    SearchMode.person => await repository.searchByPerson(
      query.text,
      page: page,
    ),
    SearchMode.filter => await repository.discover(
      genreId: query.genreId,
      year: query.year,
      page: page,
    ),
  };

  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Genre list for the filter chips. Cached by the repository, so switching
/// modes does not re-fetch it.
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).genres();
  return switch (result) {
    Ok(:final value) => value,
    Err() => const <Genre>[],
  };
});
