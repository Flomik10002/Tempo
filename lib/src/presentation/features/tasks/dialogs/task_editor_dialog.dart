import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/data/models/task_extensions.dart';
import 'package:tempo/src/domain/entities/repeat_rule.dart';
import 'package:tempo/src/presentation/features/tasks/widgets/repeat_rule_selector.dart';

class TaskEditorDialog extends ConsumerStatefulWidget {
  final Task? task;

  const TaskEditorDialog({super.key, this.task});

  @override
  ConsumerState<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends ConsumerState<TaskEditorDialog> {
  late TextEditingController _titleController;
  DateTime? _deadline;
  RepeatRule? _repeatRule;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _deadline = widget.task?.deadline;
    _repeatRule = widget.task?.repeatRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (widget.task == null) {
      // Create
      ref.read(createTaskUseCaseProvider).call(
        title: title,
        deadline: _deadline,
        repeatRule: _repeatRule,
      );
    } else {
      // Update - пока нет use case, добавим позже или используем repo напрямую
      // ref.read(updateTaskUseCaseProvider).call(...)
      // Для MVP пока только создание
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'What needs to be done?',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_deadline == null
                    ? 'No Deadline'
                    : DateFormat.yMMMd().format(_deadline!)),
              ),
              const Spacer(),
              if (_deadline != null)
                IconButton(
                  onPressed: () => setState(() => _deadline = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RepeatRuleSelector(
            value: _repeatRule,
            onChanged: (rule) => setState(() => _repeatRule = rule),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
