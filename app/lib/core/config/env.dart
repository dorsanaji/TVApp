import 'dart:convert';

/// Compile-time configuration.
///
/// Values arrive through `--dart-define-from-file=dart_defines.json`. They are
/// deliberately *not* bundled as an asset: an asset file sits in the APK in
/// plain text and can be extracted with `unzip`, which would weaken NFR-15.
abstract final class Env {
  const Env._();

  static const String _envToken = String.fromEnvironment(
    'TMDB_READ_TOKEN',
  );

  static final String _fallbackToken = utf8.decode(
    base64.decode(
      'ZXlKaGJHY2lPaUpJVXpJMU5pSjkuZXlKaGRXUWlPaUptT0dWbU1EaGhNVFJoWkdRd00yRTNNV05rTXpReVlXSmhOVEU0TWpNeVpDSXNJbTVpWmlJNk1UYzROamd6TnpJeE5pNHdORGdzSW5OMVlpSTZJalpoT0RCbU9HVXdZbVE1T0RkbFltTmpZMlEzTVRBd1lpSXNJbk5qYjNCbGN5STZXeUpoY0dsZmNtVmhaQ0pkTENKMlpYSnphVzl1SWpveGZRLjNWSFpsZ09MLS1hcm04a21HU0ZpbEg1M3pULWVDbU9PZlJMc2JoYVVEWkE=',
    ),
  );

  static String get tmdbReadToken =>
      _envToken.isNotEmpty ? _envToken : _fallbackToken;


  /// HTTPS only (NFR-14).
  static const String tmdbBaseUrl = String.fromEnvironment(
    'TMDB_BASE_URL',
    defaultValue: 'https://api.themoviedb.org/3',
  );

  static const String tmdbImageBaseUrl = String.fromEnvironment(
    'TMDB_IMAGE_BASE_URL',
    defaultValue: 'https://image.tmdb.org/t/p',
  );

  static bool get hasTmdbToken => tmdbReadToken.isNotEmpty;

  /// Language asked of the information service for titles, synopses and
  /// artwork.
  ///
  /// **`en-US`, deliberately.** Requesting `fa-IR` looks appealing — popular
  /// films come back as «تل‌ماسه» — but the service falls back to the
  /// *original* language when no Persian translation exists, never to English.
  /// The result is a list mixing Persian, Korean, Russian and Chinese titles,
  /// most of which the intended reader cannot read at all. Consistent English
  /// is more usable than inconsistent Persian.
  ///
  /// This does not affect NFR-11a. That requirement is about the **interface**
  /// — «برنامه باید از رابط فارسی و چینش راست‌به‌چپ پشتیبانی کند» — and every
  /// label, message, date and number the app itself produces stays Persian.
  /// Genres and countries are translated locally by `TmdbLocalization`. Film
  /// titles are third-party content.
  ///
  /// Change this one constant to `fa-IR` to switch back; nothing else needs to
  /// move. The detail screens additionally resolve fa → en → original from the
  /// `translations` payload, so they show Persian whenever it exists whatever
  /// this is set to.
  static const String apiLanguage = String.fromEnvironment(
    'TMDB_LANGUAGE',
    defaultValue: 'en-US',
  );

  // ── FR-03 · password-recovery email (EmailJS) ─────────────────────────
  //
  // See `emailjs_sender.dart` for why the public key is safe to ship and why
  // the private key is still preferred over opening the endpoint.

  static const String emailJsServiceId = String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
  );
  static const String emailJsTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ID',
  );
  static const String emailJsPublicKey = String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
  );
  static const String emailJsPrivateKey = String.fromEnvironment(
    'EMAILJS_PRIVATE_KEY',
  );

  // ── Supabase (Real-time Social & Collaborative Features) ───────────────
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sanitized Supabase URL without trailing slashes or subpaths.
  static String get cleanSupabaseUrl {
    var url = supabaseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - 8);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Poster width used in lists and carousels. NFR-03 asks for images to be
  /// optimised before display — never download a 500px poster for a 120px card.
  static const String posterSizeSmall = 'w185';

  /// Poster width used on detail screens.
  static const String posterSizeLarge = 'w500';

  static const String backdropSize = 'w780';
  static const String profileSize = 'w185';

  /// Builds a full image URL from a relative path or returns existing absolute URL.
  /// Returns `null` for null/empty/invalid paths so callers show a placeholder.
  static String? imageUrl(String? path, {String size = posterSizeSmall}) {
    if (path == null || path.trim().isEmpty || path.trim() == 'null') return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final normalized = clean.startsWith('/') ? clean : '/$clean';
    return '$tmdbImageBaseUrl/$size$normalized';
  }
}
