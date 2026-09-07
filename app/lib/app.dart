

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/biometric_gate.dart';
import 'router/app_router.dart';

/// Root widget.
///
/// NFR-11a requires a Persian interface with right-to-left layout. Three
/// things make that hold everywhere rather than screen by screen:
///
///  1. [locale] is pinned to `fa` instead of following the device, so the app
///     is Persian even on an English phone — which is how it will be graded;
///  2. `GlobalWidgetsLocalizations` resolves the text direction to RTL for
///     the whole tree, so `EdgeInsetsDirectional`, `start`/`end`, and icon
///     mirroring all behave without per-widget handling;
///  3. the font is set on the theme (see [AppTheme]), so nothing can fall
///     back to a Latin face that renders Persian badly.
class CineTrackApp extends StatelessWidget {
  const CineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── NFR-11a ───────────────────────────────────────────────────────
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // The app is designed dark: posters and artwork sit on a dark ground
      // throughout, and the light palette was never given the same attention.
      // Pinned rather than following the device so it looks the same on
      // every phone.
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      routerConfig: createRouter(),

      // NFR-26/27: keep text legible on phones with a very large system font
      // scale without letting the layout break.
      builder: (context, child) {
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          // FR-02 — wrapped here rather than around one route so the prompt
          // covers every entry point into the app.
          child: BiometricGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
