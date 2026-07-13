import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFFF6B35);
const Color kAccentColor = Color(0xFFE63946);
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kSurfaceElevated = Color(0xFF262626);
const Color kTextPrimary = Color(0xFFF5F5F5);
const Color kTextSecondary = Color(0xFFB8B8B8);

ThemeData buildFitLogTheme() {
  final baseTheme = ThemeData.dark(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.dark,
    secondary: kAccentColor,
  );

  return baseTheme.copyWith(
    colorScheme: colorScheme.copyWith(
      primary: kPrimaryColor,
      secondary: kAccentColor,
      surface: kSurfaceColor,
      surfaceContainerHighest: kSurfaceElevated,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
    ),
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: kBackgroundColor,
      foregroundColor: kTextPrimary,
      elevation: 0,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
        fontSize: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurfaceColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor)),
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: kTextSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textTheme: baseTheme.textTheme.copyWith(
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: kTextPrimary),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: kTextPrimary),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kTextPrimary),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(color: kTextSecondary),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(color: kTextSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: kSurfaceColor,
      contentTextStyle: const TextStyle(color: kTextPrimary),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}

SnackBar buildStyledSnackBar(String message, {Color? color}) {
  return SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: color ?? kSurfaceColor,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

void showFitLogSnackBar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(buildStyledSnackBar(message, color: color));
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

PageRouteBuilder<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
  );
}

PageRouteBuilder<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    ),
  );
}
