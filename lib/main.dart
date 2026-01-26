import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations, DefaultWidgetsLocalizations, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/app_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TempoApp()));
}

class TempoApp extends ConsumerWidget {
  const TempoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return CupertinoApp(
      title: 'Tempo',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: themeMode == ThemeMode.dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        barBackgroundColor: themeMode == ThemeMode.dark ? const Color(0xFF1C1C1E) : const Color(0xF0F9F9F9),
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