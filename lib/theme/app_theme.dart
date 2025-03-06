import 'package:flutter/material.dart';

/// Defines the app's theme configuration
class AppTheme {
  /// Creates the light theme for the app
  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green.shade600,
      brightness: Brightness.light,
      primary: Colors.green.shade600,
      secondary: Colors.teal.shade500,
      tertiary: Colors.amber.shade600,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true, 
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: colorScheme.shadow.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIconColor: colorScheme.primary.withOpacity(0.7),
        suffixIconColor: colorScheme.primary.withOpacity(0.7),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface.withOpacity(0.8),
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Creates the dark theme for the app
  static ThemeData darkTheme() {
    // Create a dark color scheme based on green
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green.shade600,
      brightness: Brightness.dark,
      primary: Colors.green.shade400,
      secondary: Colors.teal.shade300,
      tertiary: Colors.amber.shade400,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onBackground: Colors.white.withOpacity(0.87),
      onSurface: Colors.white.withOpacity(0.87),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
        color: darkColorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkColorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: darkColorScheme.primary.withOpacity(0.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: darkColorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: darkColorScheme.surfaceVariant.withOpacity(0.3),
        labelStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
        prefixIconColor: darkColorScheme.primary.withOpacity(0.8),
        suffixIconColor: darkColorScheme.primary.withOpacity(0.8),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
      ),
      iconTheme: IconThemeData(
        color: darkColorScheme.onSurface.withOpacity(0.8),
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: darkColorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
        space: 24,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkColorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalElevation: 8,
      ),
    );
  }
}
