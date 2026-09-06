import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_spacing.dart';

/// Helper to resolve image provider from either URL, Base64 Data URI, or local File.
ImageProvider? resolveAvatarProvider(String? path) {
  if (path == null || path.trim().isEmpty || path.trim() == 'null') return null;
  final clean = path.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return CachedNetworkImageProvider(clean);
  }
  if (clean.startsWith('data:image')) {
    final comma = clean.indexOf(',');
    if (comma != -1) {
      try {
        final b64 = clean.substring(comma + 1);
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
  }
  try {
    final file = File(clean);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// FR-01 — «تصویر پروفایل به‌صورت اختیاری».
///
/// The brief lists a profile picture among the registration fields, marked
/// optional. Only the path is kept: the image itself stays where the gallery
/// put it, so the database holds no binary data and a large photo cannot bloat
/// it (NFR-40).
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    required this.path,
    required this.onChanged,
    this.initial,
    this.radius = 44,
    super.key,
  });

  /// Absolute path of the chosen file, or `null` when none is set.
  final String? path;

  final ValueChanged<String?> onChanged;

  /// Letter shown when there is no picture — the user's first initial.
  final String? initial;

  final double radius;

  Future<void> _pick(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80,
      );
      if (picked != null) onChanged(picked.path);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('انتخاب تصویر ممکن نشد')),
      );
      debugPrint('avatar pick failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = resolveAvatarProvider(path);
    final hasImage = imageProvider != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: imageProvider,
              onBackgroundImageError: imageProvider != null
                  ? (_, _) {
                      // Prevent unhandled exception when local/network avatar fails to load
                    }
                  : null,
              child: hasImage
                  ? null
                  : Text(
                      initial ?? '؟',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
            PositionedDirectional(
              bottom: 0,
              end: 0,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _pick(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasImage)
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('حذف تصویر'),
          )
        else
          TextButton(
            onPressed: () => _pick(context),
            child: const Text('افزودن تصویر (اختیاری)'),
          ),
      ],
    );
  }
}

/// Shows a user's avatar wherever one is displayed, falling back to their
/// initial. Supports local files, HTTP URLs, and Base64 Data URIs.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.path,
    required this.initial,
    this.radius = 20,
    super.key,
  });

  final String? path;
  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedPath = path?.trim();
    final cleanPath = (trimmedPath != null &&
            trimmedPath.isNotEmpty &&
            trimmedPath != 'null')
        ? trimmedPath
        : null;

    final initialText = initial.trim().isNotEmpty
        ? initial.trim().characters.first
        : '؟';

    Widget buildFallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          initialText,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    if (cleanPath == null) {
      return buildFallback();
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: CachedNetworkImageProvider(cleanPath),
        onBackgroundImageError: (_, _) {},
        child: Text(
          initialText,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    // File or memory image provider
    final imageProvider = resolveAvatarProvider(cleanPath);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: imageProvider,
      onBackgroundImageError: (_, _) {},
      child: imageProvider != null
          ? null
          : Text(
              initialText,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}
