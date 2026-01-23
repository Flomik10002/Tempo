import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, BoxShadow, Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:gap/gap.dart';
import 'package:glass/glass.dart';
import 'package:drift/drift.dart' show Value;

import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TempoApp()));
}

class TempoApp extends StatelessWidget {
  const TempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Tempo',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: RootLayout(),
    );
  }
}

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _index = 0;

  final _pages = const [
    HomeView(),
    TasksView(),
    CalendarView(),
    BodyMapView(),
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
          left: 0,
          right: 0,
          bottom: 0,
          child: CNTabBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              CNTabBarItem(label: 'Timer', icon: CNSymbol('timer')),
              CNTabBarItem(label: 'Tasks', icon: CNSymbol('checklist')),
              CNTabBarItem(label: 'History', icon: CNSymbol('calendar')),
              CNTabBarItem(label: 'Body', icon: CNSymbol('figure.arms.open')),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final duration = ref.watch(currentDurationProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Gap(20),
            Text(
              activeSession == null ? 'No active session' : 'Focusing...',
              style: const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
            const Gap(40),

            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Session Time', style: TextStyle(color: CupertinoColors.systemGrey)),
                      const CNIcon(symbol: CNSymbol('clock', color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Gap(20),
                  if (activeSession != null)
                    CNButton.icon(
                      icon: const CNSymbol('stop.fill'),
                      onPressed: () => ref.read(timerControllerProvider).toggleSession(activeSession.activityId),
                    )
                  else
                    const Text('Select activity below', style: TextStyle(color: CupertinoColors.systemBlue)),
                ],
              ),
            ),

            const Gap(24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Activities', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
            ),
            const Gap(12),

            activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) return const Text("Restart app to seed DB");
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: activities.map((act) {
                    final isActive = activeSession?.activityId == act.id;
                    return GestureDetector(
                      onTap: () => ref.read(timerControllerProvider).toggleSession(act.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: isActive
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? Colors.transparent : CupertinoColors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: Color(int.parse(act.color)),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              act.name,
                              style: TextStyle(
                                color: isActive ? Colors.white : CupertinoColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const CupertinoActivityIndicator(),
              error: (e, s) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text('Tasks', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
                const Spacer(),
                CNButton.icon(
                  icon: const CNSymbol('plus'),
                  onPressed: () => _addTask(context, ref),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: CNSegmentedControl(
                labels: const ['Active', 'Done'],
                selectedIndex: 0,
                onValueChanged: (i) {},
              ),
            ),
          ),
          const Gap(20),

          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) return const Center(child: Text("No tasks", style: TextStyle(color: CupertinoColors.systemGrey)));
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  itemCount: tasks.length,
                  separatorBuilder: (_,__) => const Gap(12),
                  itemBuilder: (ctx, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key('${task.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => db.delete(db.tasks).delete(task),
                      background: Container(
                        decoration: BoxDecoration(color: CupertinoColors.destructiveRed, borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(CupertinoIcons.trash, color: Colors.white),
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => db.update(db.tasks).replace(task.copyWith(isCompleted: !task.isCompleted)),
                              child: Icon(
                                task.isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                                color: task.isCompleted ? CupertinoColors.activeGreen : CupertinoColors.systemGrey3,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? CupertinoColors.systemGrey : CupertinoColors.black,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e,s) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return CupertinoAlertDialog(
            title: const Text('New Task'),
            content: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CupertinoTextField(controller: ctrl, placeholder: 'Task name', autofocus: true),
            ),
            actions: [
              CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              CupertinoDialogAction(isDefaultAction: true, onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  final db = ref.read(databaseProvider);
                  db.into(db.tasks).insert(TasksCompanion.insert(title: ctrl.text));
                }
                Navigator.pop(ctx);
              }, child: const Text('Add')),
            ],
          );
        }
    );
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: Text('History (Coming Soon)', style: TextStyle(color: CupertinoColors.systemGrey))),
    );
  }
}

class BodyMapView extends StatelessWidget {
  const BodyMapView({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: Text('Body Map (Coming Soon)', style: TextStyle(color: CupertinoColors.systemGrey))),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupertinoColors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF000000).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    ).asGlass(tintColor: Colors.white, clipBorderRadius: BorderRadius.circular(24), blurX: 10, blurY: 10);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}