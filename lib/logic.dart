import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/database.dart';

// DB Access
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// --- THEME ---
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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
      query.where((t) => t.isCompleted.not());
      break;
    case TaskFilter.scheduled:
      query.where((t) => t.isCompleted.not() & t.dueDate.isNotNull());
      break;
    case TaskFilter.repeating:
      query.where((t) => t.isCompleted.not() & t.isRepeating);
      break;
    case TaskFilter.done:
      query.where((t) => t.isCompleted);
      break;
  }

  return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

// --- CALENDAR ---
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final sessionsForDateProvider = StreamProvider.autoDispose.family<List<SessionWithActivity>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final query = db.select(db.sessions).join([
    leftOuterJoin(db.activities, db.activities.id.equalsExp(db.sessions.activityId))
  ])
    ..where(
        db.sessions.startTime.isBiggerOrEqualValue(startOfDay) &
        db.sessions.startTime.isSmallerThanValue(endOfDay) &
        db.sessions.endTime.isNotNull()
    );

  return query.watch().map((rows) {
    return rows.map((row) {
      if (row.readTableOrNull(db.activities) == null) return null;
      return SessionWithActivity(
        session: row.readTable(db.sessions),
        activity: row.readTable(db.activities),
      );
    }).whereType<SessionWithActivity>().toList();
  });
});

class SessionWithActivity {
  final Session session;
  final Activity activity;
  SessionWithActivity({required this.session, required this.activity});
}

// --- TIMER ---
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

  Future<void> stopSession() async {
    final active = await (db.select(db.sessions)..where((s) => s.endTime.isNull())).getSingleOrNull();
    if (active != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id))).write(
        SessionsCompanion(endTime: Value(DateTime.now())),
      );
    }
  }

  Future<void> _start(int id) async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(activityId: id, startTime: DateTime.now()));
  }

  // Activities
  Future<void> addActivity(String name, String color) async {
    await db.into(db.activities).insert(ActivitiesCompanion.insert(name: name, color: color));
  }

  Future<void> updateActivity(Activity activity) async {
    await db.update(db.activities).replace(activity);
  }

  Future<void> deleteActivity(int id) async {
    await (db.delete(db.activities)..where((a) => a.id.equals(id))).go();
  }

  // Tasks
  Future<void> toggleTask(Task task) async {
    await db.update(db.tasks).replace(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(Task task) async {
    await db.delete(db.tasks).delete(task);
  }

  Future<void> updateTask(Task task, String title, String? desc, DateTime? dueDate, bool isRepeating) async {
    await db.update(db.tasks).replace(task.copyWith(
      title: title,
      description: Value(desc),
      dueDate: Value(dueDate),
      isRepeating: isRepeating,
    ));
  }

  Future<void> addTask(String title, String? desc, DateTime? dueDate, bool isRepeating) async {
    await db.into(db.tasks).insert(TasksCompanion.insert(
      title: title,
      description: Value(desc),
      dueDate: Value(dueDate),
      isRepeating: Value(isRepeating),
    ));
  }

  // Calendar
  Future<void> addSegment(DateTime start, DateTime end, int activityId) async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      activityId: activityId,
      startTime: start,
      endTime: Value(end),
    ));
  }

  Future<void> deleteSession(int sessionId) async {
    await (db.delete(db.sessions)..where((s) => s.id.equals(sessionId))).go();
  }

  Future<void> updateSegmentTime(int sessionId, DateTime start, DateTime end) async {
    await (db.update(db.sessions)..where((s) => s.id.equals(sessionId))).write(
      SessionsCompanion(startTime: Value(start), endTime: Value(end)),
    );
  }
}

final appControllerProvider = Provider((ref) => AppController(ref.watch(databaseProvider)));