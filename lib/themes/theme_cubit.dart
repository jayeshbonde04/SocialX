import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'isDarkMode';

  ThemeCubit(this._prefs) : super(ThemeInitial()) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDarkMode = _prefs.getBool(_themeKey) ?? false;
    emit(ThemeLoaded(isDarkMode));
  }

  Future<void> toggleTheme() async {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      final newIsDarkMode = !currentState.isDarkMode;
      await _prefs.setBool(_themeKey, newIsDarkMode);
      emit(ThemeLoaded(newIsDarkMode));
    }
  }

  bool get isDarkMode {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.isDarkMode;
    }
    return false;
  }
} 