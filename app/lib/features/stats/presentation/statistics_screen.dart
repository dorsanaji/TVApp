import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/l10n/persian_numbers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../reviews/presentation/review_providers.dart';
import '../../tracking/presentation/tracking_providers.dart';

/// FR-19 §5.19 — the six activity statistics the brief enumerates.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);
    final averageRating = ref.watch(myAverageRatingProvider).valueOrNull;
    // The same counters the profile shows, so this screen can never contradict
    // the number the user just read one tap earlier.
    final counters = ref.watch(profileCountersProvider).valueOrNull;

    final appBar = AppBar(title: const Text('آمار فعالیت'));

    if (statsAsync case AsyncError(:final error)) {
      return Scaffold(
        appBar: appBar,
        body: ErrorView(
          failure: error is Failure ? error : ErrorMapper.fromUnknown(error),
          onRetry: () => ref.invalidate(statisticsProvider),
        ),
      );
    }

    final stats = statsAsync.valueOrNull;
    if (stats == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // "Nothing to show" must mean the account really is empty — not merely
    // that nothing has been marked *watched* yet. A user who is part-way
    // through two series and has a favourite has plainly been active, and
    // telling them otherwise reads as a broken screen.
    final hasStatistics =
        stats.moviesWatched > 0 ||
        stats.seriesWatched > 0 ||
        stats.episodesWatched > 0 ||
        stats.totalMinutesWatched > 0 ||
        stats.favouriteGenre != null ||
        averageRating != null;
    final hasTracking =
        counters != null &&
        (counters.moviesWatched > 0 ||
            counters.seriesFollowed > 0 ||
            counters.favourites > 0);

    return Scaffold(
      appBar: appBar,
      body: !(hasStatistics || hasTracking)
          ? const EmptyState(
              icon: Icons.insights_outlined,
              message:
                  'هنوز فعالیتی ثبت نشده است.\n'
                  'وضعیت تماشای فیلم‌ها و سریال‌ها را ثبت کنید تا آمار شما ساخته شود.',
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.bottomInset(context, extra: AppSpacing.lg),
              ),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      icon: Icons.movie_outlined,
                      // 1 · تعداد فیلم‌های مشاهده شده
                      label: 'فیلم‌های دیده‌شده',
                      value: stats.moviesWatched.toPersian,
                    ),
                    _StatCard(
                      icon: Icons.live_tv_outlined,
                      // 2 · تعداد سریال‌های مشاهده شده
                      label: 'سریال‌های دیده‌شده',
                      value: stats.seriesWatched.toPersian,
                    ),
                    _StatCard(
                      icon: Icons.playlist_play,
                      // 3 · تعداد قسمت‌های مشاهده شده
                      label: 'قسمت‌های دیده‌شده',
                      value: stats.episodesWatched.toPersian,
                    ),
                    _StatCard(
                      icon: Icons.schedule,
                      // 4 · مجموع زمان تقریبی تماشا
                      label: 'زمان تقریبی تماشا',
                      value: Formatters.totalWatchTime(
                        stats.totalMinutesWatched,
                      ),
                    ),
                    _StatCard(
                      icon: Icons.category_outlined,
                      // 5 · ژانر موردعلاقه کاربر
                      label: 'ژانر موردعلاقه',
                      value: stats.favouriteGenre ?? '—',
                    ),
                    _StatCard(
                      icon: Icons.star_outline,
                      // 6 · میانگین امتیازهای ثبت شده
                      label: 'میانگین امتیازها',
                      value: averageRating == null
                          ? '—'
                          : averageRating
                                .toStringAsFixed(1)
                                .replaceAll('.', '٫')
                                .toPersianDigits,
                    ),
                  ],
                ),
                if (stats.genreBreakdown.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'توزیع ژانرها',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GenreChart(breakdown: stats.genreBreakdown),
                ],
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar chart of the genres behind statistic 5, so "favourite genre" is shown
/// with the evidence rather than as a bare label.
class _GenreChart extends StatelessWidget {
  const _GenreChart({required this.breakdown});

  final Map<String, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Top six keeps the axis readable on a phone.
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final maxValue = top.first.value.toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue + 1,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      top[index].key,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < top.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].value.toDouble(),
                    color: theme.colorScheme.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
