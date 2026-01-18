import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Dismissible, DismissDirection, ValueKey; // Use minimal material
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tempo/src/core/di/parts/use_case_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart' hide ActivityType;
import 'package:tempo/src/data/models/task_extensions.dart';
import 'package:tempo/src/presentation/core/widgets/tempo_design_system.dart';

class TaskCardWidget extends ConsumerWidget {
  final Task task;

  const TaskCardWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = task.status == TaskStatus.done;

    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        color: CupertinoColors.destructiveRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
         // TODO: Implement delete
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TempoCard(
          padding: EdgeInsets.zero,
          child: CupertinoButton(
            padding: const EdgeInsets.all(16),
            onPressed: () {
              // TODO: Open edit dialog
            },
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    if (!isDone) {
                       ref.read(completeTaskUseCaseProvider).call(task.id);
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone 
                            ? CupertinoColors.activeBlue 
                            : CupertinoColors.systemGrey4,
                        width: 2,
                      ),
                      color: isDone ? CupertinoColors.activeBlue : Colors.transparent,
                    ),
                    child: isDone 
                        ? const Icon(CupertinoIcons.checkmark, size: 16, color: CupertinoColors.white) 
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone 
                              ? TempoDesign.textSecondary 
                              : TempoDesign.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (task.deadline != null || task.repeatRule != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (task.deadline != null) ...[
                              _buildDateBadge(task.deadline!),
                              const SizedBox(width: 8),
                            ],
                            if (task.repeatRule != null)
                              const TempoBadge(
                                text: 'Repeats',
                                color: CupertinoColors.systemIndigo,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    final isOverdue = taskDate.isBefore(today);
    final isToday = taskDate.isAtSameMomentAs(today);
    final isTomorrow = taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)));
    
    Color color = CupertinoColors.systemGrey;
    String text = DateFormat.MMMd().format(date);
    
    if (isOverdue) {
      color = CupertinoColors.destructiveRed;
      text = 'Overdue';
    } else if (isToday) {
      color = CupertinoColors.activeOrange;
      text = 'Due Today';
    } else if (isTomorrow) {
      color = CupertinoColors.activeOrange;
      text = 'Due Tomorrow';
    }

    return TempoBadge(text: text, color: color);
  }
}
