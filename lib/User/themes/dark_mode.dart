import 'package:flutter/material.dart';
import 'light_mode.dart' show AppGradients;

// Football-themed color palette
const Color _primaryBlue = Color(0xFF2596be);
const Color _darkBlue = Color(0xFF243443);
const Color _accentYellow = Color(0xFFfdbe33);
const Color _cream = Color(0xFFfef5d8);
const Color _lightGray = Color(0xFFd8d9dd);
const Color _offWhite = Color(0xFFfafafa);

// Dark mode gradients
final LinearGradient _darkPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    _primaryBlue,
    Color(0xFF1e7ba5),
  ],
);

final LinearGradient _darkAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    _accentYellow,
    Color(0xFFe6a529),
  ],
);

final LinearGradient _darkBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    _darkBlue,
    Color(0xFF1a2730),
  ],
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: _primaryBlue,
    secondary: _accentYellow,
    tertiary: _darkBlue,
    surface: _darkBlue,
    inversePrimary: _cream,
    onPrimary: Colors.white,
    onSecondary: _darkBlue,
    onTertiary: _cream,
    surfaceContainerHighest: _darkBlue.withOpacity(0.8),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: _darkBlue,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: _primaryBlue),
    titleTextStyle: TextStyle(
      color: _cream,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    color: _darkBlue.withOpacity(0.8),
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

// Export gradients for use in widgets
final AppGradients darkGradients = _DarkGradients();

class _DarkGradients implements AppGradients {
  @override
  final LinearGradient primary = _darkPrimaryGradient;
  
  @override
  final LinearGradient accent = _darkAccentGradient;
  
  @override
  final LinearGradient background = _darkBackgroundGradient;
  
  @override
  LinearGradient get glass => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
  );
}
