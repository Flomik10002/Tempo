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

// --- ACTIVITIES ---

final activitiesStreamProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.activities)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
});

// --- TASKS FILTERS ---

enum TaskFilter { active, scheduled, repeating, done }

final tasksProvider = StreamProvider.autoDispose.family<List<Task>, TaskFilter>((ref, filter) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.tasks);

  switch (filter) {
    case TaskFilter.active:
    // Все невыполненные
      query.where((t) => t.isCompleted.not());
      break;
    case TaskFilter.scheduled:
    // Невыполненные с датой
      query.where((t) => t.isCompleted.not() & t.dueDate.isNotNull());
      break;
    case TaskFilter.repeating:
    // Невыполненные повторяющиеся
      query.where((t) => t.isCompleted.not() & t.isRepeating);
      break;
    case TaskFilter.done:
    // Только выполненные
      query.where((t) => t.isCompleted);
      break;
  }

  return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

// --- CALENDAR & SESSIONS ---

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Сессии для конкретного дня
final sessionsForDateProvider = StreamProvider.autoDispose.family<List<SessionWithActivity>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);

  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final query = db.select(db.sessions).join([
    leftOuterJoin(db.activities, db.activities.id.equalsExp(db.sessions.activityId))
  ])
    ..where(
        db.sessions.startTime.isBiggerOrEqualValue(startOfDay) &
        db.sessions.startTime.isSmallerThanValue(endOfDay)
    );

  return query.watch().map((rows) {
    return rows.map((row) {
      return SessionWithActivity(
        session: row.readTable(db.sessions),
        activity: row.readTable(db.activities),
      );
    }).toList();
  });
});

class SessionWithActivity {
  final Session session;
  final Activity activity;
  SessionWithActivity({required this.session, required this.activity});
}

// --- TIMER LOGIC ---

final activeSessionProvider = StreamProvider.autoDispose<Session?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sessions)..where((s) => s.endTime.isNull())).watchSingleOrNull();
});

final currentDurationProvider = Provider.autoDispose<Duration>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null) return Duration.zero;
  ref.watch(tickerProvider);
  return DateTime.now().difference(session.startTime);
});

final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

// --- CONTROLLER ---

class AppController {
  final AppDatabase db;
  AppController(this.db);

  // Timer
  Future<void> toggleSession(int activityId) async {
    final active = await (db.select(db.sessions)..where((s) => s.endTime.isNull())).getSingleOrNull();
    if (active != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id))).write(
        SessionsCompanion(endTime: Value(DateTime.now())),
      );
      if (active.activityId != activityId) await _start(activityId);
    } else {
      await _start(activityId);
    }
  }

  Future<void> _start(int id) async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(activityId: id, startTime: DateTime.now()));
  }

  // Activities
  Future<void> addActivity(String name, String color) async {
    await db.into(db.activities).insert(ActivitiesCompanion.insert(name: name, color: color));
  }

  // Tasks
  Future<void> toggleTask(Task task) async {
    // Просто инвертируем статус. Если станет Done - уйдет во вкладку Done.
    await db.update(db.tasks).replace(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(Task task) async {
    await db.delete(db.tasks).delete(task);
  }

  // Calendar
  Future<void> addSegment(DateTime start, int activityId) async {
    // Добавляем сегмент длительностью 1 час по умолчанию
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      activityId: activityId,
      startTime: start,
      endTime: Value(start.add(const Duration(hours: 1))),
    ));
  }

  Future<void> updateSegmentTime(int sessionId, DateTime start, DateTime end) async {
    await (db.update(db.sessions)..where((s) => s.id.equals(sessionId))).write(
      SessionsCompanion(startTime: Value(start), endTime: Value(end)),
    );
  }
}

final appControllerProvider = Provider((ref) => AppController(ref.watch(databaseProvider)));