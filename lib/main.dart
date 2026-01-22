import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, BoxShadow, Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:gap/gap.dart';
import 'package:glass/glass.dart';
// Убрал лишний импорт drift/drift.dart

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

// --- Layout with CNTabBar ---

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

// --- 1. HOME (TIMER) ---

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final duration = ref.watch(currentDurationProvider);

    final activitiesAsync = ref.watch(StreamProvider((ref) => ref.watch(databaseProvider).select(ref.watch(databaseProvider).activities).watch()));

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
              data: (activities) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: activities.map((act) {
                  final isActive = activeSession?.activityId == act.id;
                  return GestureDetector(
                    onTap: () => ref.read(timerControllerProvider).toggleSession(act.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: isActive
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CupertinoColors.white.withOpacity(0.2),
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
              ),
              loading: () => const CupertinoActivityIndicator(),
              error: (e,s) => Text('Error: $e'),
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

// --- 2. TASKS ---

class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final tasksAsync = ref.watch(StreamProvider((ref) => ref.watch(databaseProvider).select(ref.watch(databaseProvider).tasks).watch()));

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
              data: (tasks) => ListView.separated(
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
                          if (task.dueDate != null)
                            const CNIcon(symbol: CNSymbol('calendar.badge.clock', color: CupertinoColors.systemRed)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e,s) => Text('$e'),
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
              child: CupertinoTextField(controller: ctrl, placeholder: 'Task name'),
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

// --- 3. CALENDAR ---

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Calendar', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
            const Gap(20),
            GlassCard(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CNIcon(symbol: CNSymbol('calendar', size: 48, color: CupertinoColors.systemGrey3)),
                      const Gap(10),
                      Text('Timeline Coming Soon', style: TextStyle(color: CupertinoColors.systemGrey.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. BODY MAP ---

class BodyMapView extends StatelessWidget {
  const BodyMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: GridPainter()),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Body Map', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
                const Text('AI Muscle Analysis', style: TextStyle(color: CupertinoColors.systemGrey)),
                const Gap(40),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMannequin('Front'),
                      _buildMannequin('Side'),
                      _buildMannequin('Back'),
                    ],
                  ),
                ),

                const Gap(80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMannequin(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 250,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: const Center(
            child: CNIcon(symbol: CNSymbol('figure.stand', size: 40, color: CupertinoColors.systemGrey)),
          ),
        ).asGlass(
          tintColor: Colors.white,
          clipBorderRadius: BorderRadius.circular(40),
        ),
        const Gap(10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// --- Helper Widgets ---

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    ).asGlass(
      tintColor: Colors.white,
      clipBorderRadius: BorderRadius.circular(24),
      blurX: 10,
      blurY: 10,
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.systemGrey6
      ..strokeWidth = 1;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}