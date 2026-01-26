import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Dismissible, DismissDirection, Icons, Divider, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';
import 'package:tempo/presentation/widgets/native_glass_container.dart';

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
                      child: GestureDetector(
                        onTap: () => _showTaskDialog(context, ref, task: task),
                        child: NativeGlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdaptiveCheckbox(
                                value: task.isCompleted,
                                onChanged: (val) => ref.read(appControllerProvider).toggleTask(task),
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
                                          : CupertinoColors.label.resolveFrom(context),
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

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task == null ? 'New Task' : 'Edit Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.label.resolveFrom(context))),
                    const Gap(20),
                    AdaptiveTextField(controller: titleCtrl, placeholder: 'Title', autofocus: task == null),
                    const Gap(12),
                    AdaptiveTextField(controller: descCtrl, placeholder: 'Description', maxLines: 3),
                    const Gap(20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Due Date', style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
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
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Repeat Daily', style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
                        AdaptiveSwitch(value: isRepeating, onChanged: (v) => setState(() => isRepeating = v)),
                      ],
                    ),
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AdaptiveButton(label: 'Cancel', style: AdaptiveButtonStyle.plain, onPressed: () => Navigator.pop(ctx)),
                        const Gap(8),
                        AdaptiveButton(label: 'Save', onPressed: () {
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
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}