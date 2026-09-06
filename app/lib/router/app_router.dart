import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../domain/entities/media_summary.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/details/presentation/movie_detail_screen.dart';
import '../features/details/presentation/series_detail_screen.dart';
import '../features/episodes/presentation/season_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/lists/presentation/lists_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/social/presentation/activity_feed_screen.dart';
import '../features/social/presentation/collaborative_list_screen.dart';
import '../features/social/presentation/public_profile_screen.dart';
import '../features/stats/presentation/statistics_screen.dart';
import '../features/tracking/presentation/watchlist_screen.dart';

/// Application routes.
///
/// A [StatefulShellRoute] gives each tab its own navigator, so switching tabs
/// preserves scroll position and in-progress input rather than rebuilding —
/// which matters for NFR-01 and for the feel of the app.
///
/// Detail, episode, review, and admin routes are added by their own phases.
/// Route guards for the guest/member split (§4.1) arrive with Phase 4, via a
/// `redirect` that consults the auth repository.
abstract final class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const search = '/search';
  static const watchlist = '/watchlist';
  static const lists = '/lists';
  static const profile = '/profile';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const statistics = '/statistics';
  static const activityFeed = '/activity-feed';

  static String publicProfile(String userId) => '/user/$userId';
  static String collaborativeList(String listId) =>
      '/collaborative-list/$listId';

  static String movie(int id) => '/movie/$id';
  static String series(int id) => '/series/$id';
  static String season(int seriesId, int seasonNumber) =>
      '/series/$seriesId/season/$seasonNumber';
}

/// Navigation helpers, so screens do not have to know how a title maps to a
/// route. Films and series have separate detail screens (FR-06 vs. FR-07) but
/// appear side by side in search results and carousels.
extension MediaNavigation on BuildContext {
  void goToDetail(MediaSummary item) => push(
    item.type.isMovie ? AppRoutes.movie(item.id) : AppRoutes.series(item.id),
  );

  void goToSeason(int seriesId, int seasonNumber) =>
      push(AppRoutes.season(seriesId, seasonNumber));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.watchlist,
                builder: (context, state) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.lists,
                builder: (context, state) => const ListsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Auth and statistics sit on the root navigator, above the tab bar.
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.activityFeed,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ActivityFeedScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/collaborative-list/:listId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CollaborativeListScreen(
          listId: state.pathParameters['listId'] ?? '',
        ),
      ),

      // Detail routes sit on the root navigator so they cover the tab bar —
      // a full-screen context for FR-06, FR-07 and FR-08.
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            MovieDetailScreen(movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(
        path: '/series/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SeriesDetailScreen(
          seriesId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'season/:seasonNumber',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SeasonScreen(
              seriesId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              seasonNumber: int.tryParse(state.pathParameters['seasonNumber'] ?? '') ?? 1,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Bottom navigation shell (NFR-08 — main sections easily accessible).
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab returns it to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: AppStrings.navSearch,
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: AppStrings.tabWatchlist,
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_add_check_outlined),
            selectedIcon: Icon(Icons.playlist_add_check_rounded),
            label: AppStrings.tabLists,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
