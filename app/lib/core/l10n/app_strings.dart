/// Persian user-facing copy (NFR-11a).
///
/// Centralised so that every string the user can see lives in one place. This
/// keeps the interface consistently Persian and makes an later migration to
/// ARB/`gen_l10n` mechanical if a second locale is ever wanted.
abstract final class AppStrings {
  const AppStrings._();

  // ── App ────────────────────────────────────────────────────────────────
  static const appName = 'هم‌سکانس';

  // ── Navigation (NFR-08: main sections easily accessible) ───────────────
  // Screen titles — the full names, as the brief uses them.
  static const navHome = 'خانه';
  static const navSearch = 'جست‌وجو';
  static const navSocial = 'اجتماعی';
  static const navWatchlist = 'فهرست تماشا';
  static const navLists = 'فهرست‌های من';
  static const navProfile = 'پروفایل';

  // Bottom-bar labels.
  //
  // Shorter than the screen titles on purpose. Five destinations sharing a
  // phone's width leaves roughly 70dp each; «فهرست تماشا» and «فهرست‌های من»
  // wrapped onto two lines and collided with their icons and each other.
  // Paired with the bar's icons these read unambiguously, and the full names
  // still appear in each screen's app bar.
  static const tabWatchlist = 'تماشا';
  static const tabLists = 'فهرست‌ها';

  // ── Home sections (FR-18) ──────────────────────────────────────────────
  static const sectionPopularMovies = 'فیلم‌های محبوب';
  static const sectionPopularSeries = 'سریال‌های محبوب';
  static const sectionNewReleases = 'آثار جدید';
  static const sectionTopRated = 'آثار دارای امتیاز بالا';
  static const sectionSuggestions = 'پیشنهادی برای شما';

  // ── Watch statuses (FR-09) ─────────────────────────────────────────────
  static const statusPlanToWatch = 'قصد دارم تماشا کنم';
  static const statusWatching = 'در حال تماشا';
  static const statusWatched = 'مشاهده شده';

  /// FR-16's heart, not an FR-09 status — see [WatchStatus].
  static const statusFavourite = 'موردعلاقه';

  // ── Watchlist sections (FR-12) ─────────────────────────────────────────
  static const watchlistWatching = 'در حال تماشا';
  static const watchlistWatched = 'مشاهده شده';
  static const watchlistLater = 'بعداً تماشا می‌کنم';
  static const watchlistFavourites = 'موردعلاقه‌ها';

  // ── Errors (FR-20 — the four conditions named in the brief) ────────────
  static const errorNoConnection = 'اتصال اینترنت برقرار نیست';
  static const errorFetchFailed = 'دریافت اطلاعات با خطا مواجه شد';
  static const errorNotFound = 'فیلم یا سریال موردنظر پیدا نشد';
  static const errorServiceUnavailable = 'سرویس اطلاعاتی در دسترس نیست';
  static const errorUnauthorized = 'برای این کار باید وارد حساب خود شوید';

  // ── Common actions ─────────────────────────────────────────────────────
  static const retry = 'تلاش دوباره';
  static const cancel = 'انصراف';
  static const confirm = 'تأیید';
  static const save = 'ذخیره';
  static const delete = 'حذف';
  static const edit = 'ویرایش';
  static const undo = 'بازگرداندن';
  static const loading = 'در حال بارگذاری…';

  // ── Empty states ───────────────────────────────────────────────────────
  static const emptySearchPrompt = 'نام فیلم یا سریال را جست‌وجو کنید';
  static const emptyNoResults = 'نتیجه‌ای یافت نشد';
  static const emptyWatchlist = 'هنوز اثری به فهرست تماشای خود اضافه نکرده‌اید';
  static const emptyLists = 'هنوز فهرست شخصی نساخته‌اید';

  // ── Attribution (required by the TMDB terms of use) ────────────────────
  static const tmdbAttribution =
      'این برنامه از API سرویس TMDB استفاده می‌کند، اما مورد تأیید یا '
      'گواهی‌شده توسط TMDB نیست.';

  // ── Placeholder shown while a phase is still unimplemented ─────────────
  static const comingSoon = 'این بخش در مرحله‌ی بعدی پیاده‌سازی می‌شود';
}
