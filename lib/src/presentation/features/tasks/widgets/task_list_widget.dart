import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/features/tasks/providers/tasks_provider.dart';
import 'package:tempo/src/presentation/features/tasks/widgets/task_card_widget.dart';

class TaskListWidget extends ConsumerWidget {
  final TaskStatus status;

  const TaskListWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByStatusProvider(status));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == TaskStatus.done
                      ? Icons.task_alt
                      : Icons.checklist,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  status == TaskStatus.done
                      ? 'No completed tasks yet'
                      : 'No active tasks',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCardWidget(task: task);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
