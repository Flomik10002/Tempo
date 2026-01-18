import 'package:flutter/material.dart';
import 'package:tempo/src/data/database/drift_database.dart' hide ActivityType;
import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/presentation/core/theme/tempo_colors.dart'; // Надо будет создать или использовать hardcoded цвета пока

class SessionSegmentWidget extends StatelessWidget {
  final Session session;
  final ActivityType activityType;
  final double height;
  final double width;

  const SessionSegmentWidget({
    super.key,
    required this.session,
    required this.activityType,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Делаем цвет немного прозрачным для фона
    final color = Color(int.parse(activityType.color.replaceAll('#', '0xFF')));
    
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.only(left: 8, top: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activityType.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (height > 30)
            Text(
              session.note ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
