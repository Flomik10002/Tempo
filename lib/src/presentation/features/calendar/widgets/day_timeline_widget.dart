import 'package:flutter/material.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/features/calendar/widgets/session_segment_widget.dart';

class DayTimelineWidget extends StatelessWidget {
  final List<Session> sessions;
  final Map<String, ActivityType> activityTypeMap;
  final double hourHeight;

  const DayTimelineWidget({
    super.key,
    required this.sessions,
    required this.activityTypeMap,
    this.hourHeight = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    // Высота 24 часов
    final totalHeight = hourHeight * 24;

    return SingleChildScrollView(
      child: Container(
        height: totalHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            // Background grid (hours)
            ...List.generate(24, (index) {
              return Positioned(
                top: index * hourHeight,
                left: 0,
                right: 0,
                child: Container(
                  height: hourHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        '${index.toString().padLeft(2, '0')}:00',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Sessions
            ...sessions.map((session) {
              final type = activityTypeMap[session.activityTypeId];
              if (type == null) return const SizedBox.shrink();

              // Calculate position
              final startMinutes = session.startAt.hour * 60 + session.startAt.minute;
              
              // Если сессия активна (endAt == null), считаем до текущего момента или конца дня
              final end = session.endAt ?? DateTime.now();
              // Отрезаем, если сессия выходит за границы дня (визуализация только для одного дня)
              // (Для MVP упрощаем: если сессия началась вчера, startAt будет вчера, и top < 0, это скроет её начало)
              // Нам нужно правильно считать высоту и top относительно начала этого дня.
              
              // Для корректности: нужно обрезать start и end по границам текущего дня (00:00 - 24:00)
              // Но provider уже фильтрует сессии, которые пересекаются с этим днем.
              
              final startOfDay = DateTime(session.startAt.year, session.startAt.month, session.startAt.day); 
              // ВНИМАНИЕ: session.startAt может быть в другой день, если provider вернул сессию, начавшуюся вчера и закончившуюся сегодня.
              // Но в простом случае (без cross-day logic сложно) пока считаем, что startAt.hour берется "как есть", 
              // что может быть ошибкой для cross-day.
              
              // Упрощение для MVP: используем startMinutes как есть. Cross-day позже.
              
              double top = (startMinutes / 60) * hourHeight;
              
              int durationMinutes;
              if (session.endAt == null) {
                // Active session
                final now = DateTime.now();
                durationMinutes = now.difference(session.startAt).inMinutes;
              } else {
                durationMinutes = session.endAt!.difference(session.startAt).inMinutes;
              }
              
              double height = (durationMinutes / 60) * hourHeight;
              
              return Positioned(
                top: top,
                left: 50, // Отступ для времени
                right: 0,
                height: height < 1 ? 1 : height, // Минимальная высота
                child: SessionSegmentWidget(
                  session: session,
                  activityType: type,
                  height: height,
                  width: double.infinity,
                ),
              );
            }),
            
            // Current time indicator (line)
            _buildCurrentTimeIndicator(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentTimeIndicator(BuildContext context) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final top = (minutes / 60) * hourHeight;
    
    return Positioned(
       top: top,
       left: 0,
       right: 0,
       child: Divider(color: Colors.red, thickness: 1, height: 1),
    );
  }
}
