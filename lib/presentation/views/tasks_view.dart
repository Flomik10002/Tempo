import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, Icons, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/app_container.dart';

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
                // Обычная кнопка, не нативная
                AdaptiveButton.icon(
                    
                    icon: CupertinoIcons.add,
                    onPressed: () => _showTaskDialog(context, ref),
                    style: AdaptiveButtonStyle.plain
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: AdaptiveSegmentedControl(
                labels: const ['Active', 'Scheduled', 'Repeat', 'Done'],
                selectedIndex: _filter.index,
                onValueChanged: (index) {
                  setState(() => _filter = TaskFilter.values[index]);
                },
              ),
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
                      child: AppContainer( // Легкий контейнер
                        onTap: () => _showTaskDialog(context, ref, task: task),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ЛЕГКИЙ ЧЕКБОКС (Кнопка с иконкой) вместо тяжелого AdaptiveCheckbox
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

  // _showTaskDialog оставляем как был, он использует модалку, там можно и Adaptive виджеты
  void _showTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    DateTime? pickedDate = task?.dueDate;
    bool isRepeating = task?.isRepeating ?? false;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Material(
          color: Colors.transparent,
          child: CupertinoActionSheet(
            title: Text(task == null ? 'New Task' : 'Edit Task'),
            message: Column(
              children: [
                const Gap(16),
                CupertinoTextField(controller: titleCtrl, placeholder: 'Title'),
                const Gap(12),
                CupertinoTextField(controller: descCtrl, placeholder: 'Description', maxLines: 3),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Date'),
                    AdaptiveButton(
                      
                      style: AdaptiveButtonStyle.tinted,
                      label: pickedDate == null ? 'Set Date' : DateFormat('MMM d').format(pickedDate!),
                      onPressed: () async {
                        final date = await AdaptiveDatePicker.show(context: context, initialDate: DateTime.now());
                        if(date != null) setState(() => pickedDate = date);
                      },
                    )
                  ],
                ),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Repeat Daily'),
                    // Тут свитч безопасен, это модалка
                    AdaptiveSwitch(value: isRepeating, onChanged: (v) => setState(() => isRepeating = v)),
                  ],
                ),
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    if (task == null) {
                      ref.read(appControllerProvider).addTask(titleCtrl.text, descCtrl.text, pickedDate, isRepeating);
                    } else {
                      ref.read(appControllerProvider).updateTask(task, titleCtrl.text, descCtrl.text, pickedDate, isRepeating);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              )
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
        ),
      ),
    );
  }
}