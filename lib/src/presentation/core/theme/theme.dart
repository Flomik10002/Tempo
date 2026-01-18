// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';

import 'src/theme_data.dart';

export 'src/theme_data.dart';

/// Extension on [BuildContext] to provide convenient access to theme-related
/// properties and utilities.
extension BuildContextExtension on BuildContext {
  /// Internal getter to access the current theme data.
  ThemeData get _theme => Theme.of(this);

  /// Gets the light theme data configuration.
  ThemeData get lightTheme => $LightThemeData()();

  /// Gets the dark theme data configuration.
  ThemeData get darkTheme => $DarkThemeData()();
}
