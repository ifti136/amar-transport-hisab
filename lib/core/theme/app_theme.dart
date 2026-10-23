import 'package:flutter/material.dart';
import 'colors.dart';

/// Light Theme (M0)
ThemeData lightTheme([bool isBn = true]) {
  return _buildTheme(
    brightness: Brightness.light,
    isBn: isBn,
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.tertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiary: AppColors.onTertiary,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    onError: AppColors.onError,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccess: AppColors.onSuccess,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarning: AppColors.onWarning,
    danger: AppColors.danger,
    dangerContainer: AppColors.dangerContainer,
    onDanger: AppColors.onDanger,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    chartGreen: AppColors.chartGreen,
    chartRed: AppColors.chartRed,
    chartBlue: AppColors.chartBlue,
    chartOrange: AppColors.chartOrange,
    chartPurple: AppColors.chartPurple,
    chartTeal: AppColors.chartTeal,
    chartVermillion: AppColors.chartVermillion,
  );
}

/// Dark Theme (M0b)
ThemeData darkTheme([bool isBn = true]) {
  return _buildTheme(
    brightness: Brightness.dark,
    isBn: isBn,
    primary: const Color(0xFF81C784), // Light green
    primaryContainer: const Color(0xFF1B5E20),
    onPrimary: const Color(0xFF000000),
    secondary: const Color(0xFF90CAF9), // Light blue
    secondaryContainer: const Color(0xFF0D47A1),
    onSecondary: const Color(0xFF000000),
    tertiary: const Color(0xFFFFB74D), // Light orange
    tertiaryContainer: const Color(0xFFE65100),
    onTertiary: const Color(0xFF000000),
    error: const Color(0xFFEF9A9A),
    errorContainer: const Color(0xFFC62828),
    onError: const Color(0xFF000000),
    success: const Color(0xFFA5D6A7),
    successContainer: const Color(0xFF1B5E20),
    onSuccess: const Color(0xFF000000),
    warning: const Color(0xFFFFB74D),
    warningContainer: const Color(0xFFE65100),
    onWarning: const Color(0xFF000000),
    danger: const Color(0xFFEF9A9A),
    dangerContainer: const Color(0xFFC62828),
    onDanger: const Color(0xFF000000),
    surface: const Color(0xFF1E1E1E),
    surfaceVariant: const Color(0xFF2C2C2C),
    onSurface: const Color(0xFFFFFFFF),
    onSurfaceVariant: const Color(0xFFB0B0B0),
    outline: const Color(0xFF757575),
    outlineVariant: const Color(0xFF424242),
    background: const Color(0xFF121212),
    onBackground: const Color(0xFFFFFFFF),
    chartGreen: const Color(0xFF66BB6A),
    chartRed: const Color(0xFFFFA726),
    chartBlue: const Color(0xFF42A5F5),
    chartOrange: const Color(0xFFFFB74D),
    chartPurple: const Color(0xFFBA68C8),
    chartTeal: const Color(0xFF4DB6AC),
    chartVermillion: const Color(0xFFEF5350),
  );
}

ThemeData _buildTheme({
  required Brightness brightness,
  required bool isBn,
  required Color primary,
  required Color primaryContainer,
  required Color onPrimary,
  required Color secondary,
  required Color secondaryContainer,
  required Color onSecondary,
  required Color tertiary,
  required Color tertiaryContainer,
  required Color onTertiary,
  required Color error,
  required Color errorContainer,
  required Color onError,
  required Color success,
  required Color successContainer,
  required Color onSuccess,
  required Color warning,
  required Color warningContainer,
  required Color onWarning,
  required Color danger,
  required Color dangerContainer,
  required Color onDanger,
  required Color surface,
  required Color surfaceVariant,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color outline,
  required Color outlineVariant,
  required Color background,
  required Color onBackground,
  required Color chartGreen,
  required Color chartRed,
  required Color chartBlue,
  required Color chartOrange,
  required Color chartPurple,
  required Color chartTeal,
  required Color chartVermillion,
}) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    primaryContainer: primaryContainer,
    onPrimary: onPrimary,
    secondary: secondary,
    secondaryContainer: secondaryContainer,
    onSecondary: onSecondary,
    tertiary: tertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiary: onTertiary,
    error: error,
    errorContainer: errorContainer,
    onError: onError,
    surface: surface,
    surfaceContainerHighest: surfaceVariant,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    background: background,
    onBackground: onBackground,
    surfaceContainer: surfaceVariant,
    surfaceContainerHigh: surfaceVariant,
    surfaceContainerLow: surface,
    surfaceContainerLowest: background,
    inverseSurface: brightness == Brightness.light ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
    onInverseSurface: brightness == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF121212),
    inversePrimary: brightness == Brightness.light ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,

    // Typography - Bengali gets larger line height
    textTheme: TextTheme(
      displayLarge: _textStyle(57, FontWeight.normal, isBn ? 1.6 : 1.4),
      displayMedium: _textStyle(45, FontWeight.normal, isBn ? 1.6 : 1.4),
      displaySmall: _textStyle(36, FontWeight.normal, isBn ? 1.6 : 1.4),
      headlineLarge: _textStyle(32, FontWeight.w500, isBn ? 1.5 : 1.4),
      headlineMedium: _textStyle(28, FontWeight.w500, isBn ? 1.5 : 1.4),
      headlineSmall: _textStyle(24, FontWeight.w500, isBn ? 1.5 : 1.4),
      titleLarge: _textStyle(22, FontWeight.w500, isBn ? 1.5 : 1.4),
      titleMedium: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4),
      titleSmall: _textStyle(14, FontWeight.w500, isBn ? 1.5 : 1.4),
      bodyLarge: _textStyle(16, FontWeight.normal, isBn ? 1.6 : 1.4),
      bodyMedium: _textStyle(14, FontWeight.normal, isBn ? 1.6 : 1.4),
      bodySmall: _textStyle(12, FontWeight.normal, isBn ? 1.6 : 1.4),
      labelLarge: _textStyle(14, FontWeight.w500, isBn ? 1.5 : 1.4),
      labelMedium: _textStyle(12, FontWeight.w500, isBn ? 1.5 : 1.4),
      labelSmall: _textStyle(11, FontWeight.w500, isBn ? 1.5 : 1.4),
    ).apply(
      fontFamily: isBn ? 'NotoSansBengali' : 'Roboto',
      bodyColor: onSurface,
      displayColor: onSurface,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      backgroundColor: surface,
      foregroundColor: onSurface,
      titleTextStyle: _textStyle(22, FontWeight.w500, isBn ? 1.5 : 1.4, color: onSurface),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4),
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4),
        foregroundColor: primary,
        side: BorderSide(color: outline, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4),
        foregroundColor: primary,
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: _textStyle(16, FontWeight.normal, isBn ? 1.6 : 1.4, color: onSurfaceVariant),
      hintStyle: _textStyle(16, FontWeight.normal, isBn ? 1.6 : 1.4, color: onSurfaceVariant),
      errorStyle: _textStyle(12, FontWeight.normal, isBn ? 1.5 : 1.4, color: error),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),

    // Cards
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      color: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: brightness == Brightness.light ? Colors.black26 : Colors.black54,
    ),

    // Chips
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: _textStyle(14, FontWeight.normal, isBn ? 1.5 : 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: surfaceVariant,
      selectedColor: primaryContainer,
      checkmarkColor: primary,
      side: BorderSide.none,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    ),

    // Dialogs
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      surfaceTintColor: Colors.transparent,
      backgroundColor: surface,
      titleTextStyle: _textStyle(22, FontWeight.w500, isBn ? 1.5 : 1.4, color: onSurface),
      contentTextStyle: _textStyle(16, FontWeight.normal, isBn ? 1.6 : 1.4, color: onSurface),
    ),

    // Bottom Sheets
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      backgroundColor: surface,
    ),

    // Navigation Bar
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      indicatorColor: primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _textStyle(12, FontWeight.w500, isBn ? 1.5 : 1.4, color: primary);
        }
        return _textStyle(12, FontWeight.normal, isBn ? 1.5 : 1.4, color: onSurfaceVariant);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary, size: 24);
        }
        return IconThemeData(color: onSurfaceVariant, size: 24);
      }),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 6,
      shape: const CircleBorder(),
      backgroundColor: primary,
      foregroundColor: onPrimary,
      extendedTextStyle: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: _textStyle(14, FontWeight.normal, isBn ? 1.5 : 1.4),
      actionTextColor: primary,
      backgroundColor: onSurface.withValues(alpha: 0.9),
      actionBackgroundColor: primaryContainer,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // List Tile
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _textStyle(16, FontWeight.w500, isBn ? 1.5 : 1.4, color: onSurface),
      subtitleTextStyle: _textStyle(14, FontWeight.normal, isBn ? 1.6 : 1.4, color: onSurfaceVariant),
      leadingAndTrailingTextStyle: _textStyle(14, FontWeight.normal, isBn ? 1.5 : 1.4, color: onSurfaceVariant),
      iconColor: onSurfaceVariant,
      tileColor: Colors.transparent,
      selectedTileColor: primaryContainer,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      textStyle: _textStyle(12, FontWeight.normal, isBn ? 1.5 : 1.4),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Progress Indicators
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: primaryContainer,
      circularTrackColor: primaryContainer,
    ),

    // Tab Bar
    tabBarTheme: TabBarTheme(
      labelStyle: _textStyle(14, FontWeight.w500, isBn ? 1.5 : 1.4),
      unselectedLabelStyle: _textStyle(14, FontWeight.normal, isBn ? 1.5 : 1.4),
      labelColor: primary,
      unselectedLabelColor: onSurfaceVariant,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 3),
        insets: const EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Scaffold
    scaffoldBackgroundColor: background,

    // Extensions for custom colors
    extensions: <ThemeExtension<dynamic>>[
      AppChartColors(
        green: chartGreen,
        red: chartRed,
        blue: chartBlue,
        orange: chartOrange,
        purple: chartPurple,
        teal: chartTeal,
        vermillion: chartVermillion,
      ),
      AppSemanticColors(
        success: success,
        successContainer: successContainer,
        onSuccess: onSuccess,
        warning: warning,
        warningContainer: warningContainer,
        onWarning: onWarning,
        danger: danger,
        dangerContainer: dangerContainer,
        onDanger: onDanger,
      ),
    ],
  );
}

TextStyle _textStyle(
  double size,
  FontWeight weight,
  double height, {
  Color? color,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: 0, // No letter spacing for Bengali
  );
}

/// Custom theme extension for chart colors
class AppChartColors extends ThemeExtension<AppChartColors> {
  final Color green;
  final Color red;
  final Color blue;
  final Color orange;
  final Color purple;
  final Color teal;
  final Color vermillion;

  const AppChartColors({
    required this.green,
    required this.red,
    required this.blue,
    required this.orange,
    required this.purple,
    required this.teal,
    required this.vermillion,
  });

  @override
  AppChartColors copyWith({
    Color? green,
    Color? red,
    Color? blue,
    Color? orange,
    Color? purple,
    Color? teal,
    Color? vermillion,
  }) {
    return AppChartColors(
      green: green ?? this.green,
      red: red ?? this.red,
      blue: blue ?? this.blue,
      orange: orange ?? this.orange,
      purple: purple ?? this.purple,
      teal: teal ?? this.teal,
      vermillion: vermillion ?? this.vermillion,
    );
  }

  @override
  AppChartColors lerp(ThemeExtension<AppChartColors>? other, double t) {
    if (other is! AppChartColors) return this;
    return AppChartColors(
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      vermillion: Color.lerp(vermillion, other.vermillion, t)!,
    );
  }
}

/// Custom theme extension for semantic colors (success, warning, danger)
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color warning;
  final Color warningContainer;
  final Color onWarning;
  final Color danger;
  final Color dangerContainer;
  final Color onDanger;

  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? danger,
    Color? dangerContainer,
    Color? onDanger,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

/// Extension to access custom theme extensions
extension CustomThemeExtensions on ThemeData {
  AppChartColors get chartColors => extension<AppChartColors>()!;
  AppSemanticColors get semanticColors => extension<AppSemanticColors>()!;
}