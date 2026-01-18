import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple boolean provider: true = dark, false = light
// Or Enum if we want system preference support
enum AppThemeMode { light, dark }

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    // Default to light or check platform brightness initially?
    // Let's default to light for now as per design
    return AppThemeMode.light;
  }

  void toggle() {
    state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
  }

  void setMode(AppThemeMode mode) {
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);
