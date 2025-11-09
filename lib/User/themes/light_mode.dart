import 'package:flutter/material.dart';

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
