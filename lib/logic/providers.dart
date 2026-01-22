import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/data/database.dart';

// 1. Доступ к БД
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// --- Tasks Logic ---

final tasksStreamProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tasks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

// --- Timer Logic ---

// Активная сессия (если есть)
final activeSessionProvider = StreamProvider.autoDispose<Session?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sessions)..where((s) => s.endTime.isNull()))..watchSingleOrNull();
});

// Список активностей
final activitiesProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.activityTypes)..orderBy([(t) => OrderingTerm.asc(t.order)])).watch();
});

// Тикер таймера (обновляет UI каждую секунду, если таймер запущен)
final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (x) => x);
});

// Длительность текущей сессии
final currentDurationProvider = Provider.autoDispose<Duration>((ref) {
  final sessionAsync = ref.watch(activeSessionProvider);
  ref.watch(tickerProvider); // Подписка на тикер для перерисовки

  return sessionAsync.when(
    data: (session) {
      if (session == null) return Duration.zero;
      return DateTime.now().difference(session.startTime);
    },
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

// Методы управления (Controller)
class TimerController {
  final AppDatabase db;
  TimerController(this.db);

  Future<void> startSession(int activityId) async {
    // Сначала останавливаем любой текущий таймер
    await stopSession();
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      activityId: activityId,
      startTime: DateTime.now(),
    ));
  }

  Future<void> stopSession() async {
    // Находим активную сессию и закрываем её
    final active = await (db.select(db.sessions)..where((s) => s.endTime.isNull())).getSingleOrNull();
    if (active != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id))).write(
        SessionsCompanion(endTime: Value(DateTime.now())),
      );
    }
  }
}

final timerControllerProvider = Provider((ref) => TimerController(ref.watch(databaseProvider)));