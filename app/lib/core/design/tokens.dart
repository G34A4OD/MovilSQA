import 'package:flutter/material.dart';

/// Raw palette. Widgets should read colors from [Theme] or [AppPalette];
/// these constants exist for the theme builders only.
abstract final class AppColors {
  static const primary = Color(0xff2563eb);
  static const primaryDark = Color(0xff1d4ed8);
  static const ink = Color(0xff0f172a);
  static const background = Color(0xfff8fafc);
  static const surface = Color(0xffffffff);
  static const textSecondary = Color(0xff64748b);
  static const border = Color(0xffe2e8f0);
  static const success = Color(0xff16a34a);
  static const warning = Color(0xfff59e0b);
  static const error = Color(0xffdc2626);

  static const darkBackground = Color(0xff0b1220);
  static const darkSurface = Color(0xff111c2e);
  static const darkElevated = Color(0xff1e293b);
  static const darkText = Color(0xfff8fafc);
  static const darkTextSecondary = Color(0xff94a3b8);
  static const darkPrimary = Color(0xff60a5fa);
}

/// 4-point spacing scale.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;

  /// Collapses to zero when the platform asks for reduced motion.
  static Duration of(BuildContext context, Duration value) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : value;
}

enum Tone { neutral, info, success, warning, danger }

/// Semantic colors that Material's [ColorScheme] does not model.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.neutralContainer,
    required this.cardShadow,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;
  final Color neutralContainer;
  final Color cardShadow;

  static const light = AppPalette(
    success: Color(0xff15803d),
    successContainer: Color(0xffdcfce7),
    warning: Color(0xffb45309),
    warningContainer: Color(0xfffef3c7),
    danger: Color(0xffdc2626),
    dangerContainer: Color(0xfffee2e2),
    info: AppColors.primary,
    infoContainer: Color(0xffdbeafe),
    neutralContainer: Color(0xfff1f5f9),
    cardShadow: Color(0x0f0f172a),
  );

  static const dark = AppPalette(
    success: Color(0xff4ade80),
    successContainer: Color(0xff123524),
    warning: Color(0xfffbbf24),
    warningContainer: Color(0xff3a2a0c),
    danger: Color(0xfff87171),
    dangerContainer: Color(0xff3b1518),
    info: AppColors.darkPrimary,
    infoContainer: Color(0xff172b4d),
    neutralContainer: AppColors.darkElevated,
    cardShadow: Color(0x33000000),
  );

  /// Falls back to the brightness default so widgets also render inside a
  /// bare `MaterialApp` (as several widget tests do).
  static AppPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  Color foreground(Tone tone, ColorScheme scheme) => switch (tone) {
    Tone.neutral => scheme.onSurfaceVariant,
    Tone.info => info,
    Tone.success => success,
    Tone.warning => warning,
    Tone.danger => danger,
  };

  Color container(Tone tone) => switch (tone) {
    Tone.neutral => neutralContainer,
    Tone.info => infoContainer,
    Tone.success => successContainer,
    Tone.warning => warningContainer,
    Tone.danger => dangerContainer,
  };

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      danger: mix(danger, other.danger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      info: mix(info, other.info),
      infoContainer: mix(infoContainer, other.infoContainer),
      neutralContainer: mix(neutralContainer, other.neutralContainer),
      cardShadow: mix(cardShadow, other.cardShadow),
    );
  }
}

/// Tabular figures keep amounts aligned in lists and totals.
TextStyle moneyStyle(TextStyle? base) => (base ?? const TextStyle()).copyWith(
  fontFeatures: const [FontFeature.tabularFigures()],
  letterSpacing: -0.2,
);
