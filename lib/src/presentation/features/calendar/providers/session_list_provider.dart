import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Provider для получения списка сессий за конкретный день
final sessionsForDayProvider = StreamProvider.family<List<Session>, DateTime>((ref, date) {
  final repository = ref.watch(sessionRepositoryProvider);
  
  // Начало дня
  final from = DateTime(date.year, date.month, date.day);
  // Конец дня (начало следующего)
  final to = from.add(const Duration(days: 1));
  
  return repository
      .watchSessionsForPeriod(from: from, to: to)
      .map((list) => list.map((e) => e.session).toList());
});
