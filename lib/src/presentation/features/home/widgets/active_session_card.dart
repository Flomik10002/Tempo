import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/presentation/features/home/providers/activity_types_provider.dart';
import 'package:tempo/src/presentation/features/home/providers/current_session_provider.dart';

/// Карточка отображения активной сессии
class ActiveSessionCard extends ConsumerWidget {
  final Session? session;

  const ActiveSessionCard({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.timer_off_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const Gap(8),
              Text(
                'No active session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Получить информацию о типе активности
    final activityTypesAsync = ref.watch(activityTypesProvider);
    final elapsedTimeAsync = ref.watch(sessionElapsedTimeProvider);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название активности
            activityTypesAsync.whenData((activityTypes) {
              final typeId = session!.activityTypeId;
              final activityType = activityTypes.firstWhere(
                (a) => a.id == typeId,
                orElse: () => activityTypes.first,
              );
              
              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(activityType.color.substring(1), radix: 16) +
                            0xFF000000,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    activityType.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).value ?? const SizedBox.shrink(),
            
            const Gap(12),
            
            // Elapsed time
            elapsedTimeAsync.when(
              data: (duration) {
                if (duration == null) return const SizedBox.shrink();
                
                final hours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);
                final seconds = duration.inSeconds.remainder(60);
                
                return Text(
                  '${hours.toString().padLeft(2, '0')}:'
                  '${minutes.toString().padLeft(2, '0')}:'
                  '${seconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                );
              },
              loading: () => const Text('--:--:--'),
              error: (_, __) => const Text('--:--:--'),
            ),
          ],
        ),
      ),
    );
  }
}
