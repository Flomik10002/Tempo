import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/database.dart';

// DB Access
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// --- STREAMS ---

final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tasks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

final activitiesStreamProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.activities)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
});

// Timer Logic
final activeSessionProvider = StreamProvider.autoDispose<Session?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sessions)..where((s) => s.endTime.isNull())).watchSingleOrNull();
});

final currentDurationProvider = Provider.autoDispose<Duration>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null) return Duration.zero;

  // Тикер для обновления UI
  ref.watch(tickerProvider);

  return DateTime.now().difference(session.startTime);
});

final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

class TimerController {
  final AppDatabase db;
  TimerController(this.db);

  Future<void> toggleSession(int activityId) async {
    final active = await (db.select(db.sessions)..where((s) => s.endTime.isNull())).getSingleOrNull();

    if (active != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id))).write(
        SessionsCompanion(endTime: Value(DateTime.now())),
      );
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