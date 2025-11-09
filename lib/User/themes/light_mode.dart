import 'package:flutter/material.dart';

    
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF2596BE),
    secondary: const Color(0xFFFDBE33),
    tertiary: const Color(0xFF243443),
    surface: const Color(0xFFFAFAFA),
    surfaceContainerHighest: const Color(0xFFFEF5D8),
    inversePrimary: const Color(0xFF243443),
    onPrimary: Colors.white,
    onSecondary: const Color(0xFF243443),
    onSurface: const Color(0xFF243443),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF2596BE),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2596BE),
      foregroundColor: Colors.white,
      elevation: 3,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFDBE33),
    foregroundColor: Color(0xFF243443),
    elevation: 4,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFEF5D8).withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD8D9DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD8D9DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2596BE), width: 2),
    ),
  ),
    
// Football-themed color palette
const Color _primaryBlue = Color(0xFF2596be);
const Color _darkBlue = Color(0xFF243443);
const Color _accentYellow = Color(0xFFfdbe33);
const Color _cream = Color(0xFFfef5d8);
const Color _lightGray = Color(0xFFd8d9dd);
const Color _offWhite = Color(0xFFfafafa);

// Football-themed gradients
final LinearGradient _primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    _primaryBlue,
    Color(0xFF1e7ba5),
  ],
    
);

final LinearGradient _accentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    _accentYellow,
    Color(0xFFe6a529),
  ],
);

final LinearGradient _backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    _offWhite,
    _lightGray.withOpacity(0.3),
  ],
);

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: _primaryBlue,
    secondary: _accentYellow,
    tertiary: _cream,
    surface: _lightGray,
    inversePrimary: _darkBlue,
    onPrimary: Colors.white,
    onSecondary: _darkBlue,
    onTertiary: _darkBlue,
    surfaceContainerHighest: _lightGray.withOpacity(0.5),
  ),
  scaffoldBackgroundColor: _offWhite,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: _primaryBlue),
    titleTextStyle: TextStyle(
      color: _darkBlue,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white.withOpacity(0.8),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _primaryBlue,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
);

// Base class for gradients
abstract class AppGradients {
  LinearGradient get primary;
  LinearGradient get accent;
  LinearGradient get background;
  LinearGradient get glass;
}

// Export gradients for use in widgets
final AppGradients lightGradients = _LightGradients();

class _LightGradients implements AppGradients {
  @override
  final LinearGradient primary = _primaryGradient;
  
  @override
  final LinearGradient accent = _accentGradient;
  
  @override
  final LinearGradient background = _backgroundGradient;
  
  @override
  LinearGradient get glass => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.25),
      Colors.white.withOpacity(0.1),
    ],
  );
}
