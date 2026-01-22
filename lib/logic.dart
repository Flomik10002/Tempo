import 'dart:async';
import 'package:drift/drift.dart'; // Важно для Value и Companions
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/database.dart'; // Убедись, что файл называется database.dart

// DB Access
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// --- Timer Logic ---

// Активная сессия
final activeSessionProvider = StreamProvider.autoDispose<Session?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sessions)..where((s) => s.endTime.isNull())).watchSingleOrNull();
});

// Длительность текущей сессии (обновляется каждую секунду)
final currentDurationProvider = Provider.autoDispose<Duration>((ref) {
  final sessionAsync = ref.watch(activeSessionProvider);

  // Триггер перерисовки каждую секунду
  ref.watch(tickerProvider);

  return sessionAsync.when(
    data: (session) {
      if (session == null) return Duration.zero;
      return DateTime.now().difference(session.startTime);
    },
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

// Тикер
final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

// Контроллер таймера
class TimerController {
  final AppDatabase db;
  TimerController(this.db);

  Future<void> toggleSession(int activityId) async {
    final active = await (db.select(db.sessions)..where((s) => s.endTime.isNull())).getSingleOrNull();

    if (active != null) {
      // Stop current
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id))).write(
        SessionsCompanion(endTime: Value(DateTime.now())),
      );
      // Если нажали на другую активность — запускаем её сразу
      if (active.activityId != activityId) {
        await _start(activityId);
      }
    } else {
      await _start(activityId);
    }
  }

  Future<void> _start(int id) async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      activityId: id,
      startTime: DateTime.now(),
    ));
  }
}

final timerControllerProvider = Provider((ref) => TimerController(ref.watch(databaseProvider)));