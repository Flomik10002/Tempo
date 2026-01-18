import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // For minimal fallbacks
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/core/widgets/tempo_design_system.dart';
import 'package:tempo/src/presentation/features/tasks/dialogs/task_editor_dialog.dart';
import 'package:tempo/src/presentation/features/tasks/widgets/task_list_widget.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  int _selectedSegment = 0; // 0: Active, 1: Done

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: TempoDesign.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        trailing: CupertinoButton(
           padding: EdgeInsets.zero,
           child: const Icon(CupertinoIcons.add),
           onPressed: () => _showAddDialog(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  children: const {
                    0: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Active')),
                    1: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Done')),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSegment = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedSegment,
                children: const [
                  TaskListWidget(status: TaskStatus.active),
                  TaskListWidget(status: TaskStatus.done),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TempoButton(
                onPressed: () => _showAddDialog(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, color: TempoDesign.textPrimary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add new task',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: TempoDesign.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const TaskEditorDialog(),
    );
  }
}
