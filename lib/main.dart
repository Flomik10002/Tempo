import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Добавлен импорт
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/app_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем хранилище
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    // Переопределяем провайдер реальным значением
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const TempoApp(),
  ));
}

class TempoApp extends ConsumerWidget {
  const TempoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Теперь это берется из SharedPreferences
    final themeMode = ref.watch(themeModeProvider);
    const primaryColor = Color(0xFF007AFF);

    return AdaptiveApp(
      title: 'Tempo',
      themeMode: themeMode,

      // Material (Android)
      materialLightTheme: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      ),
      materialDarkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
      ),

      // Cupertino (iOS)
      cupertinoLightTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        barBackgroundColor: Color(0xF0F9F9F9),
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
        ),
      ),
      cupertinoDarkTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Color(0xFF000000),
        barBackgroundColor: Color(0xF01D1D1D),
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
        ),
      ),

      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: const AppLayout(),
    );
  }
}