import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Селектор активностей для быстрого старта/переключения
class ActivitySelector extends StatelessWidget {
  final List<ActivityType> activityTypes;
  final Function(ActivityType) onActivitySelected;

  const ActivitySelector({
    super.key,
    required this.activityTypes,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Отфильтровать скрытые
    final visibleTypes = activityTypes.where((a) => !a.isHidden).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visibleTypes.map((activityType) {
        return _ActivityChip(
          activityType: activityType,
          onTap: () => onActivitySelected(activityType),
        );
      }).toList(),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final ActivityType activityType;
  final VoidCallback onTap;

  const _ActivityChip({
    required this.activityType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(activityType.color.substring(1), radix: 16) + 0xFF000000,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Text(
              activityType.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
