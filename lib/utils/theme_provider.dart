import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants.dart';

/// Hive key for storing theme preference
const kThemeMode = 'themeMode';

/// Theme mode values for Hive storage
const kThemeModeLight = 'light';
const kThemeModeDark = 'dark';
const kThemeModeSystem = 'system';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromStorage();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Load theme preference from Hive storage
  void _loadThemeFromStorage() {
    final box = Hive.box(kMainBoxName);
    final savedTheme = box.get(kThemeMode, defaultValue: kThemeModeSystem);

    switch (savedTheme) {
      case kThemeModeLight:
        _themeMode = ThemeMode.light;
        break;
      case kThemeModeDark:
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Toggle between dark and light mode
  void toggleTheme() {
    if (isDarkMode) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeToStorage();
    notifyListeners();
  }

  /// Save theme preference to Hive storage
  void _saveThemeToStorage() {
    final box = Hive.box(kMainBoxName);
    String value;
    switch (_themeMode) {
      case ThemeMode.light:
        value = kThemeModeLight;
        break;
      case ThemeMode.dark:
        value = kThemeModeDark;
        break;
      default:
        value = kThemeModeSystem;
    }
    box.put(kThemeMode, value);
  }
}

/// VLag Theme definitions
class VLagTheme {
  // Primary VLag green color for buttons
  static const Color primaryGreen = Color(0xFF1DB877);
  
  // Dark Mode Colors (as specified)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkLinkBackground = Color(0xFFFFFFFF);
  static const Color darkLinkText = Color(0xFF000000);
  static const Color darkStroke = Color(0xFFFFFFFF);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF212121);
  static const Color lightLinkBackground = Color(0xFF607D8B); // blueGrey
  static const Color lightLinkText = Color(0xFFFFFFFF);
  static const Color lightStroke = Color(0xFF607D8B);

  /// Light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: GoogleFonts.karla().fontFamily,
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueGrey),
        actionsIconTheme: const IconThemeData(color: Colors.blueGrey),
        titleTextStyle: GoogleFonts.karla(
          color: Colors.blueGrey.shade700,
          fontSize: 18,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText),
        bodySmall: TextStyle(color: lightText.withValues(alpha: 0.7)),
        titleLarge: TextStyle(color: lightText),
        titleMedium: TextStyle(color: lightText),
        titleSmall: TextStyle(color: lightText),
      ),
      iconTheme: IconThemeData(color: Colors.blueGrey.shade700),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.blueGrey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.blueGrey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.blueGrey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: GoogleFonts.karla(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blueGrey,
        secondary: Colors.blueGrey.shade300,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
      ),
    );
  }

  /// Dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.karla().fontFamily,
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.karla(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: darkText),
        titleMedium: TextStyle(color: darkText),
        titleSmall: TextStyle(color: darkText),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        fillColor: const Color(0xFF1E1E1E),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: GoogleFonts.karla(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white70,
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkText,
      ),
    );
  }
}
