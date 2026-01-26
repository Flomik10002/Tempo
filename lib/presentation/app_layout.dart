import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    return AdaptiveScaffold(
      body: _pages[_index],
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AdaptiveNavigationDestination(label: 'Timer', icon: CupertinoIcons.timer), // Используем IconData для надежности
          AdaptiveNavigationDestination(label: 'Tasks', icon: CupertinoIcons.check_mark_circled),
          AdaptiveNavigationDestination(label: 'Calendar', icon: CupertinoIcons.calendar),
          AdaptiveNavigationDestination(label: 'Body', icon: CupertinoIcons.person),
          AdaptiveNavigationDestination(label: 'Settings', icon: CupertinoIcons.settings),
        ],
      ),
    );
  }
}