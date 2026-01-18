import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:tempo/src/presentation/features/calendar/pages/calendar_page.dart';
import 'package:tempo/src/presentation/features/home/pages/home_page.dart';
import 'package:tempo/src/presentation/features/tasks/pages/tasks_page.dart';

class IosMainLayout extends StatefulWidget {
  const IosMainLayout({super.key});

  @override
  State<IosMainLayout> createState() => _IosMainLayoutState();
}

class _IosMainLayoutState extends State<IosMainLayout> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _tabIndex,
          children: const [
            HomePage(),
            TasksPage(),
            CalendarPage(),
             // Optional Settings page placeholder if user wanted 4 items?
             // User example had 3. We have 3 features.
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CNTabBar(
            items: const [
              CNTabBarItem(label: 'Track', icon: CNSymbol('clock.fill')),
              CNTabBarItem(label: 'Tasks', icon: CNSymbol('checklist')),
              CNTabBarItem(label: 'Calendar', icon: CNSymbol('calendar')),
            ],
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
          ),
        ),
      ],
    );
  }
}
