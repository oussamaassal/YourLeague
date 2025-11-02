import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    // TODO: Load from shared preferences if needed
    // For now, default to light mode
    // Already initialized with light mode above
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      emit(ThemeMode.light);
    } else {
      // If system, toggle to dark
      emit(ThemeMode.dark);
    }
    // TODO: Save to shared preferences
  }

  void setTheme(ThemeMode mode) {
    emit(mode);
    // TODO: Save to shared preferences
  }
}

