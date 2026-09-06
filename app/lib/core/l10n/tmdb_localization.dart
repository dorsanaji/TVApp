/// Persian names for the information service's fixed vocabularies (NFR-11a).
///
/// The service has **no Persian translations** for these: requesting
/// `/genre/movie/list?language=fa-IR` returns every `name` as `null`, and the
/// genres embedded in a title's detail response come back in English whatever
/// language is asked for. Verified against the live API, not assumed.
///
/// So the names are mapped here. That is sound rather than a workaround: both
/// vocabularies are small, closed, and stable — TMDB's genre ids have not
/// changed in years, and ISO 3166-1 codes are a standard. Leaving "Romance"
/// and "Comedy" sitting in a Persian interface is exactly what NFR-11a is
/// about.
///
/// Anything unmapped falls back to the original English name rather than
/// showing a blank, so a new genre id degrades to readable rather than empty.
abstract final class TmdbLocalization {
  const TmdbLocalization._();

  /// TMDB genre ids → Persian. Covers both the film and series vocabularies;
  /// ids are shared between them where the genre is the same.
  static const Map<int, String> _genres = {
    // ── Film genres ──────────────────────────────────────────────────────
    28: 'اکشن',
    12: 'ماجراجویی',
    16: 'انیمیشن',
    35: 'کمدی',
    80: 'جنایی',
    99: 'مستند',
    18: 'درام',
    10751: 'خانوادگی',
    14: 'فانتزی',
    36: 'تاریخی',
    27: 'ترسناک',
    10402: 'موسیقی',
    9648: 'معمایی',
    10749: 'عاشقانه',
    878: 'علمی‑تخیلی',
    10770: 'فیلم تلویزیونی',
    53: 'هیجان‌انگیز',
    10752: 'جنگی',
    37: 'وسترن',

    // ── Series-only genres ───────────────────────────────────────────────
    10759: 'اکشن و ماجراجویی',
    10762: 'کودک',
    10763: 'خبری',
    10764: 'واقع‌نما',
    10765: 'علمی‑تخیلی و فانتزی',
    10766: 'ملودرام',
    10767: 'گفت‌وگو',
    10768: 'جنگ و سیاست',
  };

  /// ISO 3166-1 alpha-2 → Persian. Keyed by code rather than by English name:
  /// the code is stable, the name is not ("United States of America" vs
  /// "United States").
  static const Map<String, String> _countries = {
    'US': 'ایالات متحده',
    'GB': 'بریتانیا',
    'FR': 'فرانسه',
    'DE': 'آلمان',
    'IT': 'ایتالیا',
    'ES': 'اسپانیا',
    'JP': 'ژاپن',
    'KR': 'کره جنوبی',
    'CN': 'چین',
    'IN': 'هند',
    'CA': 'کانادا',
    'AU': 'استرالیا',
    'RU': 'روسیه',
    'IR': 'ایران',
    'TR': 'ترکیه',
    'MX': 'مکزیک',
    'BR': 'برزیل',
    'AR': 'آرژانتین',
    'SE': 'سوئد',
    'NO': 'نروژ',
    'DK': 'دانمارک',
    'FI': 'فنلاند',
    'NL': 'هلند',
    'BE': 'بلژیک',
    'PL': 'لهستان',
    'CZ': 'جمهوری چک',
    'AT': 'اتریش',
    'CH': 'سوئیس',
    'IE': 'ایرلند',
    'NZ': 'نیوزیلند',
    'ZA': 'آفریقای جنوبی',
    'EG': 'مصر',
    'AE': 'امارات متحده عربی',
    'HK': 'هنگ‌کنگ',
    'TW': 'تایوان',
    'TH': 'تایلند',
    'ID': 'اندونزی',
    'PH': 'فیلیپین',
    'PT': 'پرتغال',
    'GR': 'یونان',
    'HU': 'مجارستان',
    'RO': 'رومانی',
    'UA': 'اوکراین',
    'IL': 'اسرائیل',
    'CL': 'شیلی',
    'CO': 'کلمبیا',
    'PE': 'پرو',
  };

  /// Persian genre name for [id], falling back to [fallback] when unmapped.
  static String genre(int id, String fallback) => _genres[id] ?? fallback;

  /// Persian country name for an ISO 3166-1 alpha-2 [code], falling back to
  /// [fallback] when unmapped.
  static String country(String? code, String fallback) {
    if (code == null || code.isEmpty) return fallback;
    return _countries[code.toUpperCase()] ?? fallback;
  }
}
