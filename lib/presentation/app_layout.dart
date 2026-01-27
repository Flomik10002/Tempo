import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/views/calendar_view.dart';
import 'package:tempo/presentation/views/home_view.dart';
import 'package:tempo/presentation/views/settings_view.dart';
import 'package:tempo/presentation/views/tasks_view.dart';

class AppLayout extends ConsumerStatefulWidget {
  const AppLayout({super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  int _index = 0;

  final _pages = const [
    HomeView(),
    TasksView(),
    CalendarView(),
    Center(child: Text("Body Map (Coming Soon)")),
    SettingsView()
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark, // iOS: белые иконки
        statusBarIconBrightness: Brightness.light, // Android
      )
          : const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light, // iOS: чёрные иконки
        statusBarIconBrightness: Brightness.dark,
      ),
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: Platform.isIOS ? 85 : 56,
              child: IndexedStack(
                index: _index,
                children: _pages,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Platform.isIOS
                  ? CNTabBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                items: const [
                  CNTabBarItem(label: 'Timer', icon: CNSymbol('timer')),
                  CNTabBarItem(label: 'Tasks', icon: CNSymbol('checkmark.circle')),
                  CNTabBarItem(label: 'Calendar', icon: CNSymbol('calendar')),
                  CNTabBarItem(label: 'Body', icon: CNSymbol('person')),
                  CNTabBarItem(label: 'Settings', icon: CNSymbol('gear')),
                ],
              )
                  : Container(
                color: Colors.white,
                child: BottomNavigationBar(
                  currentIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
                    BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Tasks'),
                    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Body'),
                    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
