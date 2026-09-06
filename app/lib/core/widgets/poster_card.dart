import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/entities/watch_progress.dart';
import '../config/env.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import 'watch_progress_bar.dart';

/// The poster card used everywhere a title is listed.
///
/// Two requirements meet here:
///  * NM-09 / NFR-41 — posters are held in cache memory, via
///    [CachedNetworkImage], and requested at the size they are displayed at
///    rather than full resolution (NFR-03);
///  * FR-11 — when the title is a tracked series, the progress bar is drawn
///    across the **lower portion of the poster**, exactly as the brief
///    specifies.
class PosterCard extends StatelessWidget {
  const PosterCard({
    required this.item,
    this.progress,
    this.onTap,
    this.width = AppSpacing.posterCardWidth,
    this.showTitle = true,
    super.key,
  });

  final MediaSummary item;

  /// Supplied for tracked series; `null` for films and untracked titles.
  final WatchProgress? progress;

  final VoidCallback? onTap;
  final double width;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawPath = item.posterPath;
    final validPath = (rawPath != null && rawPath.trim().isNotEmpty && rawPath.trim() != 'null')
        ? rawPath.trim()
        : null;
    final imageUrl = validPath != null
        ? Env.imageUrl(validPath, size: Env.posterSizeSmall)
        : null;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The poster takes whatever height is left after the title and
            // year, rather than claiming a fixed aspect ratio and pushing them
            // out of the cell.
            //
            // With a fixed AspectRatio this overflowed by ~1px on a device with
            // a large system font scale: poster + two title lines + year came
            // to more than the grid cell allowed, and Flutter painted the
            // yellow overflow stripes. Letting the image flex absorbs any text
            // height — a longer title or a bigger accessibility font can no
            // longer break the layout (NFR-26, NFR-27).
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: AspectRatio(
                  aspectRatio: AppSpacing.posterAspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Poster(url: imageUrl, title: item.title),
                      _TypeBadge(type: item.type),
                      if (progress case final p?)
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: WatchProgressBar(progress: p),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showTitle) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Formatters.year(item.releaseDate),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.title});

  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final cleanUrl = url?.trim();
    if (cleanUrl == null ||
        cleanUrl.isEmpty ||
        cleanUrl == 'null' ||
        !cleanUrl.startsWith('http')) {
      return _Fallback(title: title);
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) =>
          ColoredBox(color: scheme.surfaceContainerHighest),
      // A missing poster must never surface as a broken-image glyph (FR-20:
      // failures degrade gracefully).
      errorWidget: (context, _, _) => _Fallback(title: title),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: title.trim().isEmpty
              ? Icon(
                  Icons.movie_outlined,
                  size: 28,
                  color: scheme.onSurfaceVariant,
                )
              : Text(
                  title,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
        ),
      ),
    );
  }
}

/// Distinguishes films from series at a glance — FR-05's results are combined,
/// so the type has to be visible without opening the title.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: AppSpacing.xs,
      start: AppSpacing.xs,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + 2,
            vertical: 2,
          ),
          child: Text(
            type.isMovie ? 'فیلم' : 'سریال',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
    );
  }
}
