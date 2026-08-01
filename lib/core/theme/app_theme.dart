import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  static ThemeData build({Color accent = AppPalette.auroraViolet}) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppPalette.canvas,
      primary: accent,
      secondary: AppPalette.auroraBlue,
      tertiary: AppPalette.auroraMagenta,
      error: AppPalette.danger,
      onSurface: AppPalette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.canvas,
      canvasColor: AppPalette.canvas,
      fontFamily: AppType.body,
      textTheme: AppType.textTheme(),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: AppType.titleM(),
        iconTheme: const IconThemeData(color: AppPalette.textPrimary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.glassStroke,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppPalette.textSecondary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.canvasOverlay,
        contentTextStyle: AppType.bodyM(color: AppPalette.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppPalette.glassStroke),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.canvasOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppPalette.glassStroke),
        ),
        titleTextStyle: AppType.titleM(),
        contentTextStyle: AppType.bodyM(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.glassFill,
        hintStyle: AppType.bodyM(color: AppPalette.textTertiary),
        labelStyle: AppType.label(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: _inputBorder(AppPalette.glassStroke),
        enabledBorder: _inputBorder(AppPalette.glassStroke),
        focusedBorder: _inputBorder(accent.withValues(alpha: 0.8)),
        errorBorder: _inputBorder(AppPalette.danger.withValues(alpha: 0.7)),
        focusedErrorBorder: _inputBorder(AppPalette.danger),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: AppPalette.glassFillStrong,
        thumbColor: Colors.white,
        overlayColor: accent.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppPalette.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? accent : AppPalette.glassFillStrong),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: 1),
      );
}
