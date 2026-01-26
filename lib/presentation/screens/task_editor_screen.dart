import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:tempo/database.dart';
import 'package:tempo/logic.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskEditorScreen({super.key, this.task});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _pickedDate;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _pickedDate = widget.task?.dueDate;
    _isRepeating = widget.task?.isRepeating ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: isEditing ? 'Edit Task' : 'New Task',
        // Кнопка "Сохранить" в навбаре
        actions: [
          AdaptiveAppBarAction(
            title: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DETAILS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor)),
              const Gap(8),
              // Используем нативные поля ввода
              AdaptiveTextField(
                controller: _titleCtrl,
                placeholder: 'Task Title',
                textCapitalization: TextCapitalization.sentences,
              ),
              const Gap(12),
              AdaptiveTextField(
                controller: _descCtrl,
                placeholder: 'Description (optional)',
                maxLines: 4,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),

              const Gap(32),
              Text('SETTINGS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor)),
              const Gap(8),

              // Блок с датой
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due Date', style: TextStyle(fontSize: 17, color: labelColor)),
                    // Нативная кнопка выбора даты
                    AdaptiveButton(
                      style: AdaptiveButtonStyle.tinted,
                      size: AdaptiveButtonSize.small,
                      label: _pickedDate == null ? 'Set Date' : DateFormat('MMM d').format(_pickedDate!),
                      onPressed: () async {
                        final date = await AdaptiveDatePicker.show(
                            context: context,
                            initialDate: _pickedDate ?? DateTime.now()
                        );
                        if (date != null) setState(() => _pickedDate = date);
                      },
                    ),
                  ],
                ),
              ),

              const Gap(12),

              // Блок с повторением
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Repeat Daily', style: TextStyle(fontSize: 17, color: labelColor)),
                    // Здесь AdaptiveSwitch абсолютно безопасен и уместен
                    AdaptiveSwitch(
                      value: _isRepeating,
                      onChanged: (v) => setState(() => _isRepeating = v),
                      activeColor: CupertinoTheme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),

              if (isEditing) ...[
                const Gap(40),
                SizedBox(
                  width: double.infinity,
                  child: AdaptiveButton(
                    label: 'Delete Task',
                    style: AdaptiveButtonStyle.filled,
                    color: CupertinoColors.destructiveRed,
                    onPressed: () {
                      ref.read(appControllerProvider).deleteTask(widget.task!);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;

    if (widget.task == null) {
      ref.read(appControllerProvider).addTask(
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        _pickedDate,
        _isRepeating,
      );
    } else {
      ref.read(appControllerProvider).updateTask(
        widget.task!,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        _pickedDate,
        _isRepeating,
      );
    }
    Navigator.pop(context);
  }
}