import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection; // Немного Material для свайпов и цветов
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:tempo/data/database.dart';
import 'package:tempo/logic/providers.dart';

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
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: MainScaffold(),
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.timer), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.check_mark_circled), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.graph_square), label: 'Stats'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0: return const TimerPage();
              case 1: return const TasksPage();
              case 2: return const StatsPage(); // Заглушка для будущего
              default: return const SizedBox();
            }
          },
        );
      },
    );
  }
}

// --- PAGE 1: TIMER ---

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final duration = ref.watch(currentDurationProvider);
    final activities = ref.watch(activitiesProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Tempo')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer Display
              Text(
                activeSession.value != null ? 'Focusing...' : 'Ready?',
                style: const TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
              ),
              const Gap(10),
              Text(
                _formatDuration(duration),
                style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    fontFeatures: [FontFeature.tabularFigures()] // Моноширинные цифры
                ),
              ),
              const Gap(40),

              // Stop Button (if active)
              if (activeSession.value != null)
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  borderRadius: BorderRadius.circular(30),
                  child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => ref.read(timerControllerProvider).stopSession(),
                )
              else
              // Activity Selector (if inactive)
                activities.when(
                  data: (list) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: list.map((activity) {
                      final color = Color(int.parse(activity.color));
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => ref.read(timerControllerProvider).startSession(activity.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            border: Border.all(color: color, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            activity.name,
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const CupertinoActivityIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PAGE 2: TASKS ---

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final db = ref.read(databaseProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showAddTaskDialog(context, ref),
        ),
      ),
      child: SafeArea(
        child: tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) return const Center(child: Text('No tasks yet'));
            return ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_,__) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Dismissible(
                  key: Key(task.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: CupertinoColors.systemRed,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(CupertinoIcons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => db.delete(db.tasks).delete(task),
                  child: Container(
                    color: CupertinoColors.white,
                    child: CupertinoListTile(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? CupertinoColors.systemGrey : CupertinoColors.black,
                        ),
                      ),
                      leading: GestureDetector(
                        onTap: () {
                          db.update(db.tasks).replace(task.copyWith(isCompleted: !task.isCompleted));
                        },
                        child: Icon(
                          task.isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                          color: task.isCompleted ? CupertinoColors.activeGreen : CupertinoColors.systemGrey3,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Task'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'What needs to be done?',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final db = ref.read(databaseProvider);
                db.into(db.tasks).insert(TasksCompanion.insert(title: controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// --- PAGE 3: STATS (Placeholder for Body Map) ---

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Your Body')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_solid, size: 100, color: CupertinoColors.systemGrey4),
            Gap(20),
            Text(
              '3D Body Map Coming Soon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Gap(10),
            Text(
              'AI Analysis & Muscle tracking\nwill be available in the next update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}