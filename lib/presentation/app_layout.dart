import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Нужен для Scaffold (материаловский) чтобы не было проблем с safearea иногда
import 'package:cupertino_native/cupertino_native.dart'; // Для CNTabBar
import 'package:tempo/presentation/views/calendar_view.dart';
import 'package:tempo/presentation/views/home_view.dart';
import 'package:tempo/presentation/views/settings_view.dart';
import 'package:tempo/presentation/views/tasks_view.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
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
    // Используем Stack, чтобы положить TabBar поверх контента
    // Это предотвратит его скрытие/изменение размеров при скролле
    return CupertinoPageScaffold(
      // resizeToAvoidBottomInset: false, // Опционально, если клавиатура будет мешать
      child: Stack(
        children: [
          // Контент
          Positioned.fill(
            bottom: Platform.isIOS ? 85 : 56, // Отступ под таббар (высота CNTabBar ~85 с safe area)
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),

          // Таббар
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
                : Container( // Фолбек для Android (хотя adaptive_ui мог бы, но сделаем просто)
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
    );
  }
}