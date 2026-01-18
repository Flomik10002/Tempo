import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/database_providers.dart';
import 'package:tempo/src/data/database/database_seeder.dart';
import 'package:tempo/src/presentation/core/theme/theme_provider.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/core/gen/l10n/app_localizations.dart';
import 'src/core/logger/riverpod_log.dart';
// import 'src/presentation/core/theme/theme.dart'; // Theme extensions removed/unused
import 'src/presentation/core/widgets/ios_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(observers: [RiverpodObserver()], child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    // Инициализация БД и seed данных
    final db = ref.read(appDatabaseProvider);
    final seeder = DatabaseSeeder(db);
    await seeder.seedIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: CupertinoApp(
        title: 'Tempo',
        // onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: CupertinoThemeData(
          brightness: themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light,
          primaryColor: const Color(0xFF007AFF),
          scaffoldBackgroundColor: themeMode == AppThemeMode.dark 
              ? const Color(0xFF000000) 
              : const Color(0xFFF2F2F7),
          barBackgroundColor: themeMode == AppThemeMode.dark
              ? const Color(0xFF1C1C1E)
              : const Color(0xF0F9F9F9),
        ),
        home: const IosMainLayout(),
      ),
    );
  }
}
