import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart';
import 'package:tempo/presentation/screens/task_editor_screen.dart'; // Импорт нового экрана

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
    final labelColor = CupertinoColors.label.resolveFrom(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text('Tasks', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: labelColor)),
                const Spacer(),
                // Кнопка добавления ведет на новый экран
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(builder: (_) => const TaskEditorScreen()),
                  ),
                  child: const Icon(CupertinoIcons.add_circled_solid, size: 32),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CupertinoSlidingSegmentedControl<TaskFilter>(
              groupValue: _filter,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _filter = value);
                }
              },
              thumbColor: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                context,
              ),
              backgroundColor: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemFill,
                context,
              ),
              children: const {
                TaskFilter.active: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Active'),
                ),
                TaskFilter.scheduled: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Scheduled'),
                ),
                TaskFilter.repeating: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Repeat'),
                ),
                TaskFilter.done: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Done'),
                ),
              },
            ),
          ),

          const Gap(10),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) return Center(child: Text("Empty", style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context))));
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
                      child: AppContainer(
                        // Нажатие открывает экран редактирования
                        onTap: () => Navigator.of(context, rootNavigator: true).push(
                          CupertinoPageRoute(builder: (_) => TaskEditorScreen(task: task)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Обычная кнопка вместо нативного чекбокса
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: () => ref.read(appControllerProvider).toggleTask(task),
                              child: Icon(
                                task.isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                                size: 24,
                                color: task.isCompleted ? CupertinoTheme.of(context).primaryColor : CupertinoColors.systemGrey3.resolveFrom(context),
                              ),
                            ),
                            const Gap(12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted
                                        ? CupertinoColors.systemGrey
                                        : labelColor,
                                    fontSize: 17,
                                  ),
                                ),
                                if (task.description != null && task.description!.isNotEmpty)
                                  Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),

                                const Gap(4),
                                Row(
                                  children: [
                                    if (task.dueDate != null)
                                      Text(DateFormat('MMM d').format(task.dueDate!), style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed)),
                                    if (task.dueDate != null && task.isRepeating) const Gap(8),
                                    if (task.isRepeating)
                                      Icon(CupertinoIcons.repeat, size: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                                  ],
                                ),
                              ],
                            )),
                          ],
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
}