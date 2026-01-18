import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart' hide ActivityType;

/// Начало недели (Понедельник) для выбранной даты
final weekStartProvider = Provider.family<DateTime, DateTime>((ref, date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
});

/// Статистика активности по дням недели (Duration per day)
final weeklyActivityStatsProvider = StreamProvider.family<Map<int, Duration>, DateTime>((ref, selectedDate) {
  final startOfWeek = ref.watch(weekStartProvider(selectedDate));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  
  final repo = ref.watch(sessionRepositoryProvider);
  
  return repo.watchSessionsForPeriod(from: startOfWeek, to: endOfWeek).map((items) {
    final stats = <int, Duration>{};
    for (int i = 1; i <= 7; i++) {
      stats[i] = Duration.zero;
    }
    
    for (final item in items) {
      final session = item.session;
      final date = session.startAt;
      // Если сессия пересекает дни - это сложно. Для MVP считаем по startAt.
      // Или лучше? startAt для day counting.
      // Простая логика: весь duration приписываем дню старта.
      // TODO: Split duration across midnight if needed.
      
      final dayOfWeek = date.weekday;
      
      final duration = session.endAt?.difference(session.startAt) ?? Duration.zero; // Active sessions excluded or calc till now?
      // Если активная - считаем до сейчас?
      // Для heatmap лучше считать завершенные или до текущего момента.
      // Пусть пока завершенные.
      
      stats[dayOfWeek] = (stats[dayOfWeek] ?? Duration.zero) + duration;
    }
    return stats;
  });
});
