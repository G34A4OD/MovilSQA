import 'package:flutter/material.dart';
import 'design/tokens.dart';

abstract final class AppTheme {
  /// Light page background. Public because widget tests paint with it.
  static const cream = AppColors.background;

  static ThemeData get light => _build(
    Brightness.light,
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xffdbeafe),
      onPrimaryContainer: const Color(0xff1e3a8a),
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xffe2e8f0),
      onSecondaryContainer: AppColors.ink,
      tertiary: const Color(0xff0891b2),
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: const Color(0xfff1f5f9),
      surfaceContainerHigh: const Color(0xffeef2f7),
      surfaceContainerHighest: AppColors.border,
      outline: const Color(0xffcbd5e1),
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xfffee2e2),
      onErrorContainer: const Color(0xff7f1d1d),
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.background,
      surfaceTint: Colors.transparent,
    ),
    background: AppColors.background,
    palette: AppPalette.light,
  );

  static ThemeData get dark => _build(
    Brightness.dark,
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      onPrimary: const Color(0xff08142b),
      primaryContainer: const Color(0xff1e3a8a),
      onPrimaryContainer: const Color(0xffdbeafe),
      secondary: AppColors.darkText,
      onSecondary: AppColors.darkBackground,
      secondaryContainer: AppColors.darkElevated,
      onSecondaryContainer: AppColors.darkText,
      tertiary: const Color(0xff22d3ee),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: const Color(0xff0e1728),
      surfaceContainerLow: const Color(0xff0f1a2b),
      surfaceContainer: const Color(0xff16233a),
      surfaceContainerHigh: AppColors.darkElevated,
      surfaceContainerHighest: const Color(0xff273449),
      outline: const Color(0xff334155),
      outlineVariant: const Color(0xff22304a),
      error: const Color(0xfff87171),
      onError: const Color(0xff2b0a0a),
      errorContainer: const Color(0xff3b1518),
      onErrorContainer: const Color(0xfffecaca),
      inverseSurface: AppColors.darkText,
      onInverseSurface: AppColors.ink,
      surfaceTint: Colors.transparent,
    ),
    background: AppColors.darkBackground,
    palette: AppPalette.dark,
  );

  static TextTheme _text(ColorScheme c) {
    final base = Typography.material2021(
      platform: TargetPlatform.android,
    ).black.apply(bodyColor: c.onSurface, displayColor: c.onSurface);
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.45,
        color: c.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: c.onSurfaceVariant,
      ),
    );
  }

  static ThemeData _build(
    Brightness brightness,
    ColorScheme c, {
    required Color background,
    required AppPalette palette,
  }) {
    final text = _text(c);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: c,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      extensions: [palette],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.lg,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: Space.xs - 2),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: c.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
        minVerticalPadding: Space.sm,
        iconColor: c.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: c.onSurface,
        ),
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outline),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg - 2),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm + 2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        border: border(c.outlineVariant),
        enabledBorder: border(c.outlineVariant),
        disabledBorder: border(c.outlineVariant.withValues(alpha: 0.5)),
        focusedBorder: border(c.primary, 1.6),
        errorBorder: border(c.error),
        focusedErrorBorder: border(c.error, 1.6),
        labelStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: c.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: c.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.error),
        errorMaxLines: 3,
        prefixIconColor: c.onSurfaceVariant,
        suffixIconColor: c.onSurfaceVariant,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        indicatorColor: c.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.onSurfaceVariant,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onInverseSurface),
        insetPadding: const EdgeInsets.fromLTRB(
          Space.md,
          0,
          Space.md,
          Space.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: palette.cardShadow,
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: c.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        side: BorderSide(color: c.outlineVariant),
        labelStyle: text.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.primaryContainer,
        linearMinHeight: 3,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.inverseSurface,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: text.bodySmall?.copyWith(color: c.onInverseSurface),
      ),
    );
  }
}
