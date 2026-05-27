import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/database.dart';
import 'package:tempo/health_sync_service.dart';

// DB Access
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

// --- STORAGE ---
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// --- THEME ---
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences prefs;

  ThemeNotifier(this.prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeStr = prefs.getString('theme_mode');
    if (themeStr == 'dark') {
      state = ThemeMode.dark;
    } else if (themeStr == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await prefs.setString('theme_mode', modeStr);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

// --- ACTIVITIES ---
final activitiesStreamProvider =
    StreamProvider.autoDispose<List<Activity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.activities)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

// --- TASKS FILTERS ---
enum TaskFilter { active, scheduled, repeating, done }

final tasksProvider =
    StreamProvider.autoDispose.family<List<Task>, TaskFilter>((ref, filter) {
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

final sessionsForDateProvider = StreamProvider.autoDispose
    .family<List<SessionWithActivity>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);

  // Начало текущего дня (00:00:00)
  final startOfDay = DateTime(date.year, date.month, date.day);
  // Конец текущего дня (начало следующего 00:00:00)
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final query = db.select(db.sessions).join([
    leftOuterJoin(
        db.activities, db.activities.id.equalsExp(db.sessions.activityId))
  ])
    ..where(
        // Логика пересечения интервалов:
        // Сессия должна начаться ДО конца дня И закончиться (или еще идти) ПОСЛЕ начала дня.
        db.sessions.startTime.isSmallerThanValue(endOfDay) &
            (db.sessions.endTime.isNull() |
                db.sessions.endTime.isBiggerThanValue(startOfDay)));

  return query.watch().map((rows) {
    return rows
        .map((row) {
          if (row.readTableOrNull(db.activities) == null) return null;
          return SessionWithActivity(
            session: row.readTable(db.sessions),
            activity: row.readTable(db.activities),
          );
        })
        .whereType<SessionWithActivity>()
        .toList();
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
  return (db.select(db.sessions)..where((s) => s.endTime.isNull()))
      .watchSingleOrNull();
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
  final HealthSyncService healthSyncService;
  final SharedPreferences prefs;
  static const _sleepActivityName = 'Sleep';
  static const _syncedSleepSessionIdsKey = 'health_synced_sleep_session_ids';
  AppController(this.db, this.healthSyncService, this.prefs);

  // Timer
  Future<void> toggleSession(int activityId) async {
    final active = await (db.select(db.sessions)
          ..where((s) => s.endTime.isNull()))
        .getSingleOrNull();
    if (active != null) {
      final endTime = DateTime.now();
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id)))
          .write(
        SessionsCompanion(endTime: Value(endTime)),
      );
      await _syncSleepSessionIfNeeded(
        activityId: active.activityId,
        start: active.startTime,
        end: endTime,
        sessionId: active.id,
      );
      if (active.activityId != activityId) await _start(activityId);
    } else {
      await _start(activityId);
    }
  }

  Future<void> stopSession() async {
    final active = await (db.select(db.sessions)
          ..where((s) => s.endTime.isNull()))
        .getSingleOrNull();
    if (active != null) {
      final endTime = DateTime.now();
      await (db.update(db.sessions)..where((s) => s.id.equals(active.id)))
          .write(
        SessionsCompanion(endTime: Value(endTime)),
      );
      await _syncSleepSessionIfNeeded(
        activityId: active.activityId,
        start: active.startTime,
        end: endTime,
        sessionId: active.id,
      );
    }
  }

  Future<void> _start(int id) async {
    await db.into(db.sessions).insert(
        SessionsCompanion.insert(activityId: id, startTime: DateTime.now()));
  }

  // Activities
  Future<void> addActivity(String name, String color) async {
    await db
        .into(db.activities)
        .insert(ActivitiesCompanion.insert(name: name, color: color));
  }

  Future<void> updateActivity(Activity activity) async {
    await db.update(db.activities).replace(activity);
  }

  Future<void> deleteActivity(int id) async {
    await (db.delete(db.activities)..where((a) => a.id.equals(id))).go();
  }

  // Tasks
  Future<void> toggleTask(Task task) async {
    await db
        .update(db.tasks)
        .replace(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(Task task) async {
    await db.delete(db.tasks).delete(task);
  }

  Future<void> updateTask(Task task, String title, String? desc,
      DateTime? dueDate, bool isRepeating) async {
    await db.update(db.tasks).replace(task.copyWith(
          title: title,
          description: Value(desc),
          dueDate: Value(dueDate),
          isRepeating: isRepeating,
        ));
  }

  Future<void> addTask(
      String title, String? desc, DateTime? dueDate, bool isRepeating) async {
    await db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          description: Value(desc),
          dueDate: Value(dueDate),
          isRepeating: Value(isRepeating),
        ));
  }

  // Calendar
  Future<void> addSegment(DateTime start, DateTime end, int activityId) async {
    final sessionId =
        await db.into(db.sessions).insert(SessionsCompanion.insert(
              activityId: activityId,
              startTime: start,
              endTime: Value(end),
            ));
    await _syncSleepSessionIfNeeded(
      activityId: activityId,
      start: start,
      end: end,
      sessionId: sessionId,
    );
  }

  Future<void> deleteSession(int sessionId) async {
    final session = await (db.select(db.sessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
    if (session != null) {
      final activity = await (db.select(db.activities)
            ..where((a) => a.id.equals(session.activityId)))
          .getSingleOrNull();
      if (activity != null && _isSleepActivityName(activity.name)) {
        final end = session.endTime;
        if (end != null) {
          await healthSyncService.deleteSleepInRange(
            start: session.startTime,
            end: end,
          );
        }
        await _unmarkSleepSessionSynced(sessionId);
      }
    }
    await (db.delete(db.sessions)..where((s) => s.id.equals(sessionId))).go();
  }

  Future<void> updateSegmentTime(
      int sessionId, DateTime start, DateTime end) async {
    final session = await (db.select(db.sessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
    if (session == null) return;

    final activity = await (db.select(db.activities)
          ..where((a) => a.id.equals(session.activityId)))
        .getSingleOrNull();
    final isSleep = activity != null && _isSleepActivityName(activity.name);

    if (isSleep && session.endTime != null) {
      await healthSyncService.deleteSleepInRange(
        start: session.startTime,
        end: session.endTime!,
      );
      await _unmarkSleepSessionSynced(sessionId);
    }

    await (db.update(db.sessions)..where((s) => s.id.equals(sessionId))).write(
      SessionsCompanion(startTime: Value(start), endTime: Value(end)),
    );

    if (isSleep) {
      final success = await healthSyncService.syncSleep(
        start: start,
        end: end,
        clientRecordId: 'tempo_sleep_session_$sessionId',
      );
      if (success) {
        await _markSleepSessionSynced(sessionId);
      }
      return;
    }

    await _syncSleepSessionIfNeeded(
      activityId: session.activityId,
      start: start,
      end: end,
      sessionId: sessionId,
    );
  }

  Future<void> _syncSleepSessionIfNeeded({
    required int activityId,
    required DateTime start,
    required DateTime end,
    required int sessionId,
  }) async {
    final activity = await (db.select(db.activities)
          ..where((a) => a.id.equals(activityId)))
        .getSingleOrNull();
    if (activity == null) return;

    if (!_isSleepActivityName(activity.name)) return;

    final success = await healthSyncService.syncSleep(
      start: start,
      end: end,
      clientRecordId: 'tempo_sleep_session_$sessionId',
    );
    if (success) {
      await _markSleepSessionSynced(sessionId);
    }
  }

  Future<int> syncExistingSleepSessions() async {
    final sleepActivities = await (db.select(db.activities)
          ..where((a) => a.name.equals(_sleepActivityName)))
        .get();
    if (sleepActivities.isEmpty) return 0;

    final sleepActivityIds = sleepActivities.map((e) => e.id).toList();
    final completedSleepSessions = await (db.select(db.sessions)
          ..where(
            (s) => s.endTime.isNotNull() & s.activityId.isIn(sleepActivityIds),
          ))
        .get();

    var syncedCount = 0;
    final syncedIds = await _getSyncedSleepSessionIds();
    for (final session in completedSleepSessions) {
      final end = session.endTime;
      if (end == null) continue;
      if (syncedIds.contains(session.id)) continue;

      final success = await healthSyncService.syncSleep(
        start: session.startTime,
        end: end,
        clientRecordId: 'tempo_sleep_session_${session.id}',
      );
      if (success) {
        syncedIds.add(session.id);
        syncedCount += 1;
      }
    }

    await _setSyncedSleepSessionIds(syncedIds);
    return syncedCount;
  }

  bool _isSleepActivityName(String activityName) {
    return activityName.trim() == _sleepActivityName;
  }

  Future<Set<int>> _getSyncedSleepSessionIds() async {
    final raw = prefs.getStringList(_syncedSleepSessionIdsKey) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _setSyncedSleepSessionIds(Set<int> ids) async {
    await prefs.setStringList(
      _syncedSleepSessionIdsKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _markSleepSessionSynced(int sessionId) async {
    final ids = await _getSyncedSleepSessionIds();
    if (ids.add(sessionId)) {
      await _setSyncedSleepSessionIds(ids);
    }
  }

  Future<void> _unmarkSleepSessionSynced(int sessionId) async {
    final ids = await _getSyncedSleepSessionIds();
    if (ids.remove(sessionId)) {
      await _setSyncedSleepSessionIds(ids);
    }
  }
}

final appControllerProvider = Provider((ref) {
  return AppController(
    ref.watch(databaseProvider),
    ref.watch(healthSyncServiceProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
