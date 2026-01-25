import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, BoxShadow, Offset, FontFeature, Divider, Material, Icons, DefaultMaterialLocalizations, ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:gap/gap.dart';
import 'package:glass/glass.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

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
      localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
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
  final _pages = const [HomeView(), TasksView(), CalendarView(), BodyMapView()];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CupertinoPageScaffold(child: _pages[_index])),
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
            ],
          ),
        ),
      ],
    );
  }
}

// --- 1. HOME (TIMER & ACTIVITIES) ---

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
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Session', style: TextStyle(color: CupertinoColors.systemGrey)),
                      if (activeSession != null)
                        const CNIcon(symbol: CNSymbol('record.circle', color: CupertinoColors.systemRed))
                    ],
                  ),
                  const Gap(10),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const Gap(20),
                  if (activeSession != null)
                    CNButton.icon(icon: const CNSymbol('stop.fill'), onPressed: () => ref.read(appControllerProvider).toggleSession(activeSession.activityId))
                  else
                    const Text('Tap an activity to start', style: TextStyle(color: CupertinoColors.systemBlue)),
                ],
              ),
            ),
            const Gap(30),
            // Header with Gear Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activities', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const CNIcon(symbol: CNSymbol('gear'), color: CupertinoColors.systemGrey),
                  onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ActivitiesManagerPage())),
                ),
              ],
            ),
            const Gap(10),
            activitiesAsync.when(
              data: (activities) => Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  ...activities.map((act) => _ActivityChip(activity: act, isActive: activeSession?.activityId == act.id)),
                ],
              ),
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

class _ActivityChip extends ConsumerWidget {
  final Activity activity;
  final bool isActive;
  const _ActivityChip({required this.activity, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse(activity.color));
    return GestureDetector(
      onTap: () => ref.read(appControllerProvider).toggleSession(activity.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? CupertinoColors.activeBlue : CupertinoColors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : CupertinoColors.white.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? Colors.white : color, shape: BoxShape.circle)),
            const Gap(8),
            Text(activity.name, style: TextStyle(color: isActive ? Colors.white : CupertinoColors.black, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// --- ACTIVITIES MANAGER PAGE ---

class ActivitiesManagerPage extends ConsumerWidget {
  const ActivitiesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Activities'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showEditor(context, ref, null),
        ),
      ),
      child: SafeArea(
        child: activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) return const Center(child: Text('No activities'));
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: activities.length,
              separatorBuilder: (_,__) => const Gap(12),
              itemBuilder: (ctx, index) {
                final act = activities[index];
                return Dismissible(
                  key: Key('act_${act.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: CupertinoColors.destructiveRed,
                    child: const Icon(CupertinoIcons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(appControllerProvider).deleteActivity(act.id),
                  child: GestureDetector(
                    onTap: () => _showEditor(context, ref, act),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(width: 20, height: 20, decoration: BoxDecoration(color: Color(int.parse(act.color)), shape: BoxShape.circle)),
                          const Gap(16),
                          Text(act.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey3),
                        ],
                      ),
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
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Activity? activity) {
    final nameCtrl = TextEditingController(text: activity?.name ?? '');
    String selectedColor = activity?.color ?? '0xFF007AFF';
    final colors = ['0xFF007AFF', '0xFFFF2D55', '0xFF34C759', '0xFFFF9500', '0xFFAF52DE', '0xFF5856D6', '0xFF8E8E93', '0xFF000000'];

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity == null ? 'New Activity' : 'Edit Activity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Gap(20),
              CupertinoTextField(controller: nameCtrl, placeholder: 'Name', autofocus: true),
              const Gap(20),
              const Text('Color', style: TextStyle(color: CupertinoColors.systemGrey)),
              const Gap(10),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setState(() => selectedColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c)),
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: CupertinoColors.label, width: 3) : null,
                    ),
                  ),
                )).toList(),
              ),
              const Spacer(),
              CNButton(
                label: 'Save',
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    if (activity == null) {
                      ref.read(appControllerProvider).addActivity(nameCtrl.text, selectedColor);
                    } else {
                      ref.read(appControllerProvider).updateActivity(activity.copyWith(name: nameCtrl.text, color: selectedColor));
                    }
                    Navigator.pop(ctx);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. TASKS ---

class TasksView extends ConsumerStatefulWidget {
  const TasksView({super.key});
  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  TaskFilter _filter = TaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(_filter));

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text('Tasks', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
                const Spacer(),
                CNButton.icon(icon: const CNSymbol('plus'), onPressed: () => _showTaskDialog(context, ref)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AdaptiveSegmentedControl(
                  labels: const ['Active', 'Scheduled', 'Repeating', 'Done'],
                  selectedIndex: _filter.index,
                  onValueChanged: (index) {
                    setState(() => _filter = TaskFilter.values[index]);
                  },
                ),
              ],
            ),
          ),
          const Gap(10),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) return const Center(child: Text("Empty", style: TextStyle(color: CupertinoColors.systemGrey)));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: tasks.length,
                  separatorBuilder: (_,__) => const Gap(12),
                  itemBuilder: (ctx, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key('${task.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref.read(appControllerProvider).deleteTask(task),
                      background: Container(
                        decoration: BoxDecoration(color: CupertinoColors.destructiveRed, borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(CupertinoIcons.trash, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _showTaskDialog(context, ref, task: task),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdaptiveCheckbox(
                                value: task.isCompleted,
                                onChanged: (val) {
                                  ref.read(appControllerProvider).toggleTask(task);
                                },
                              ),
                              const Gap(12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      color: task.isCompleted ? CupertinoColors.systemGrey : CupertinoColors.black,
                                      fontSize: 17,
                                    ),
                                  ),
                                  if (task.description != null && task.description!.isNotEmpty)
                                    Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),

                                  const Gap(4),
                                  Row(
                                    children: [
                                      if (task.dueDate != null)
                                        Text(DateFormat('MMM d').format(task.dueDate!), style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed)),
                                      if (task.dueDate != null && task.isRepeating) const Gap(8),
                                      if (task.isRepeating)
                                        const Icon(CupertinoIcons.repeat, size: 12, color: CupertinoColors.systemGrey),
                                    ],
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e,s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    DateTime? pickedDate = task?.dueDate;
    bool isRepeating = task?.isRepeating ?? false;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          height: 550, // More space for keyboard
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(task == null ? 'New Task' : 'Edit Task', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  CupertinoButton(child: const Text('Save'), onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      if (task == null) {
                        ref.read(appControllerProvider).addTask(titleCtrl.text, descCtrl.text, pickedDate, isRepeating);
                      } else {
                        ref.read(appControllerProvider).updateTask(task, titleCtrl.text, descCtrl.text, pickedDate, isRepeating);
                      }
                      Navigator.pop(ctx);
                    }
                  }),
                ],
              ),
              const Gap(20),
              CupertinoTextField(controller: titleCtrl, placeholder: 'Title', autofocus: task == null),
              const Gap(12),
              CupertinoTextField(controller: descCtrl, placeholder: 'Description', maxLines: 3),
              const Gap(20),

              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Due Date'),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(pickedDate == null ? 'Set Date' : DateFormat('MMM d').format(pickedDate!)),
                    onPressed: () => _pickDate(context, (d) => setState(() => pickedDate = d)),
                  )
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Repeat Daily'),
                  AdaptiveSwitch(value: isRepeating, onChanged: (v) => setState(() => isRepeating = v)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate(BuildContext context, Function(DateTime) onPicked) {
    showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250, color: CupertinoColors.systemBackground,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: onPicked,
          ),
        )
    );
  }
}

// --- 3. CALENDAR ---

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(sessionsForDateProvider(selectedDate));

    return SafeArea(
      child: Column(
        children: [
          // Header & Add Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(DateFormat.yMMMMd().format(selectedDate), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                CNButton.icon(
                  icon: const CNSymbol('plus'),
                  onPressed: () => _addManualLog(context, ref, selectedDate),
                ),
              ],
            ),
          ),

          // Days Ribbon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 30,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (ctx, index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  final isSelected = isSameDay(date, selectedDate);
                  return GestureDetector(
                    onTap: () => ref.read(selectedDateProvider.notifier).state = date,
                    child: Container(
                      width: 50, margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? CupertinoColors.activeBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat.E().format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : CupertinoColors.systemGrey)),
                          Text(date.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : CupertinoColors.black)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          // Timeline
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 24 * 60.0, // 60px per hour
                child: Stack(
                  children: [
                    // Background Lines
                    for (int i = 0; i < 24; i++)
                      Positioned(
                        top: i * 60.0, left: 0, right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: CupertinoColors.systemGrey5))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, top: 5),
                            child: Text('$i:00', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                          ),
                        ),
                      ),

                    // Tap to Add
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) => _onTapEmpty(context, ref, details.localPosition.dy, selectedDate),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Blocks
                    sessionsAsync.when(
                      data: (items) => Stack(
                        children: items.map((item) {
                          final top = _calculateTop(item.session.startTime);
                          final height = _calculateHeight(item.session.startTime, item.session.endTime);
                          final color = Color(int.parse(item.activity.color));

                          return Positioned(
                            top: top, left: 60, right: 10, height: height,
                            child: GestureDetector(
                              onTap: () => _editSegment(context, ref, item),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Text(item.activity.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => const SizedBox(),
                      error: (e,s) => const SizedBox(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTop(DateTime start) {
    return (start.hour * 60.0) + start.minute;
  }

  double _calculateHeight(DateTime start, DateTime? end) {
    final e = end ?? DateTime.now();
    final diff = e.difference(start).inMinutes;
    return diff.toDouble().clamp(20.0, 1440.0); // Minimum 20px height
  }

  // Quick add by tapping timeline
  void _onTapEmpty(BuildContext context, WidgetRef ref, double dy, DateTime date) {
    final hour = (dy / 60).floor();
    final tapTime = DateTime(date.year, date.month, date.day, hour);
    _showAddDialog(context, ref, tapTime);
  }

  // Manual add button
  void _addManualLog(BuildContext context, WidgetRef ref, DateTime date) {
    final now = DateTime.now();
    final tapTime = DateTime(date.year, date.month, date.day, now.hour, now.minute);
    _showAddDialog(context, ref, tapTime);
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, DateTime start) {
    final activitiesAsync = ref.read(activitiesStreamProvider);
    activitiesAsync.whenData((activities) {
      if(activities.isEmpty) return;
      showCupertinoModalPopup(
          context: context,
          builder: (_) => CupertinoActionSheet(
            title: Text('Log Activity starting at ${DateFormat('HH:mm').format(start)}'),
            actions: activities.map((a) => CupertinoActionSheetAction(
              onPressed: () {
                ref.read(appControllerProvider).addSegment(start, start.add(const Duration(hours: 1)), a.id);
                Navigator.pop(context);
              },
              child: Text(a.name, style: TextStyle(color: Color(int.parse(a.color)))),
            )).toList(),
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          )
      );
    });
  }

  void _editSegment(BuildContext context, WidgetRef ref, SessionWithActivity item) {
    DateTime start = item.session.startTime;
    DateTime end = item.session.endTime ?? DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 400,
          color: CupertinoColors.systemBackground,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.activity.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Start'),
                  CupertinoButton(child: Text(DateFormat('HH:mm').format(start)), onPressed: () {
                    _pickTime(context, start, (d) => setState(() => start = d));
                  }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('End'),
                  CupertinoButton(child: Text(DateFormat('HH:mm').format(end)), onPressed: () {
                    _pickTime(context, end, (d) => setState(() => end = d));
                  }),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CNButton(label: 'Delete', onPressed: () {
                      ref.read(appControllerProvider).deleteSession(item.session.id);
                      Navigator.pop(ctx);
                    }),
                  ),
                  const Gap(10),
                  Expanded(
                    child: CNButton(label: 'Save', onPressed: () {
                      ref.read(appControllerProvider).updateSegmentTime(item.session.id, start, end);
                      Navigator.pop(ctx);
                    }),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _pickTime(BuildContext context, DateTime initial, Function(DateTime) onPicked) {
    showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 200, color: CupertinoColors.systemBackground,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: initial,
            use24hFormat: true,
            onDateTimeChanged: onPicked,
          ),
        )
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// --- 4. BODY MAP ---

class BodyMapView extends StatelessWidget {
  const BodyMapView({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Center(child: Text('Body Map (Coming Soon)', style: TextStyle(color: CupertinoColors.systemGrey))));
  }
}

// --- HELPERS ---

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