import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
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
    Center(child: Text("Body Map (Coming Soon)")), // Placeholder
    SettingsView()
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CupertinoPageScaffold(
            child: _pages[_index],
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: CNTabBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              CNTabBarItem(label: 'Timer', icon: CNSymbol('timer')),
              CNTabBarItem(label: 'Tasks', icon: CNSymbol('checklist')),
              CNTabBarItem(label: 'Calendar', icon: CNSymbol('calendar')),
              CNTabBarItem(label: 'Body', icon: CNSymbol('figure.arms.open')),
              CNTabBarItem(label: 'Settings', icon: CNSymbol('gear')),
            ],
          ),
        ),
      ],
    );
  }
}