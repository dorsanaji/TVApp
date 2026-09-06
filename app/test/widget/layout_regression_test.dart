import 'package:cinetrack/core/l10n/app_strings.dart';
import 'package:cinetrack/core/l10n/tmdb_localization.dart';
import 'package:cinetrack/core/theme/app_theme.dart';
import 'package:cinetrack/core/widgets/poster_card.dart';
import 'package:cinetrack/core/widgets/watch_progress_bar.dart';
import 'package:cinetrack/data/remote/tmdb/tmdb_mapper.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/watch_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressions for three defects found on a real device (SM S721B) that no
/// existing test caught, because they were layout and localisation faults
/// rather than logic faults.
void main() {
  /// Renders [child] the way the watchlist grid does: a fixed-size cell, RTL,
  /// with the app's real theme.
  Widget host(
    Widget child, {
    double textScale = 1.0,
    Size cell = const Size(140, 280),
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: cell.width,
                height: cell.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('PosterCard must not overflow its grid cell', () {
    const longTitle = MediaSummary(
      id: 1,
      type: MediaType.movie,
      // The title that triggered it on device — long enough to wrap to two
      // lines in Persian.
      title: 'مرد عنکبوتی: روز کاملاً جدید',
      releaseDate: '2026-07-24',
    );

    testWidgets('at the default font scale', (tester) async {
      await tester.pumpWidget(
        host(const PosterCard(item: longTitle, width: double.infinity)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('at the largest font scale the app allows (1.3)', (
      tester,
    ) async {
      // app.dart clamps the system text scaler to 1.3. This is the worst case
      // a user can actually produce, and it is what overflowed by 1.3px.
      await tester.pumpWidget(
        host(
          const PosterCard(item: longTitle, width: double.infinity),
          textScale: 1.3,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('in a cell shorter than the poster would like', (tester) async {
      await tester.pumpWidget(
        host(
          const PosterCard(item: longTitle, width: double.infinity),
          textScale: 1.3,
          // Deliberately cramped: the poster must shrink rather than the
          // column overflowing.
          cell: const Size(140, 200),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('NFR-11a · genres and countries render in Persian', () {
    test('genre ids map to Persian names', () {
      // The service returns these in English regardless of the language
      // parameter, and returns null for every name on /genre/*/list?fa-IR.
      final genres = TmdbMapper.genres([
        {'id': 10749, 'name': 'Romance'},
        {'id': 35, 'name': 'Comedy'},
        {'id': 878, 'name': 'Science Fiction'},
      ]);

      expect(genres.map((g) => g.name), ['عاشقانه', 'کمدی', 'علمی‑تخیلی']);
    });

    test('an unmapped genre id falls back to English rather than blank', () {
      final genres = TmdbMapper.genres([
        {'id': 999999, 'name': 'Some New Genre'},
      ]);

      expect(genres.single.name, 'Some New Genre');
    });

    test('countries map from their ISO code, not their English name', () {
      final countries = TmdbMapper.countries([
        {'iso_3166_1': 'MX', 'name': 'Mexico'},
        {'iso_3166_1': 'US', 'name': 'United States of America'},
        {'iso_3166_1': 'BE', 'name': 'Belgium'},
      ]);

      expect(countries, ['مکزیک', 'ایالات متحده', 'بلژیک']);
    });

    test('a country with no ISO code still renders its English name', () {
      final countries = TmdbMapper.countries([
        {'name': 'Wakanda'},
      ]);

      expect(countries, ['Wakanda']);
    });

    test('the lookup helpers are total — no id or code can crash them', () {
      expect(TmdbLocalization.genre(-1, 'fallback'), 'fallback');
      expect(TmdbLocalization.country(null, 'fallback'), 'fallback');
      expect(TmdbLocalization.country('', 'fallback'), 'fallback');
      expect(TmdbLocalization.country('zz', 'fallback'), 'fallback');
      // Case-insensitive, since the service is not guaranteed to upper-case.
      expect(TmdbLocalization.country('mx', 'fallback'), 'مکزیک');
    });
  });

  group('the bottom navigation bar fits five destinations', () {
    /// Rebuilds the real bar from the router's destinations.
    Widget navBar({required double width, required double textScale}) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              bottomNavigationBar: NavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: AppStrings.navHome,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    label: AppStrings.navSearch,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bookmark_outline),
                    label: AppStrings.tabWatchlist,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.playlist_add_check_outlined),
                    label: AppStrings.tabLists,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: AppStrings.navProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('on a narrow phone at the largest allowed font scale', (
      tester,
    ) async {
      // 360dp is the narrow end of common Android phones; 1.3 is the cap the
      // app applies to the system text scaler.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(navBar(width: 360, textScale: 1.3));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('no tab label is long enough to wrap on a narrow phone', () {
      // Roughly 72dp per destination on a 360dp screen. These labels wrapped
      // onto two lines and collided with their neighbours on device.
      const labels = [
        AppStrings.navHome,
        AppStrings.navSearch,
        AppStrings.tabWatchlist,
        AppStrings.tabLists,
        AppStrings.navProfile,
      ];

      for (final label in labels) {
        expect(
          label.length,
          lessThanOrEqualTo(9),
          reason: '"$label" is too long for a fifth of a phone\'s width',
        );
      }
    });
  });

  group('FR-11 · the progress bar actually paints its fill', () {
    Widget bar(WatchProgress progress) => MaterialApp(
      theme: AppTheme.dark,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 8,
              child: WatchProgressBar(progress: progress, height: 8),
            ),
          ),
        ),
      ),
    );

    testWidgets('the filled portion has both width and height', (tester) async {
      // 2 of 5 episodes — the case from the device screenshot, which showed
      // ۴۰٪ in text above an entirely empty bar.
      await tester.pumpWidget(
        bar(
          const WatchProgress(
            watchedEpisodes: 2,
            totalEpisodes: 5,
            hasFinishedAiring: true,
          ),
        ),
      );
      await tester.pump();

      final fill = tester.getSize(find.byType(FractionallySizedBox).first);

      // A zero-height fill is invisible however correct its width is.
      expect(
        fill.height,
        greaterThan(0),
        reason: 'the fill collapsed to 0px tall',
      );
      expect(fill.width, greaterThan(0));
    });

    testWidgets('the fill is proportional to the fraction watched', (
      tester,
    ) async {
      await tester.pumpWidget(
        bar(
          const WatchProgress(
            watchedEpisodes: 1,
            totalEpisodes: 4,
            hasFinishedAiring: true,
          ),
        ),
      );
      await tester.pump();

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(box.widthFactor, closeTo(0.25, 0.001));
      // Without this the child gets a loose height and disappears.
      expect(box.heightFactor, 1);
    });
  });
}
