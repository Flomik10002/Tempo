import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'drift_database.g.dart';

/// Таблица типов активности (Study, Code, Gym, Sleep и т.д.)
class ActivityTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  /// Цвет в формате #RRGGBB
  TextColumn get color => text()();
  /// Порядок отображения в UI
  IntColumn get order => integer()();
  /// Скрыть из календаря
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Таблица сессий активности
class Sessions extends Table {
  TextColumn get id => text()();
  /// Ссылка на тип активности
  TextColumn get activityTypeId => text().references(ActivityTypes, #id)();
  /// Время начала
  DateTimeColumn get startAt => dateTime()();
  /// Время окончания (null = активная сессия)
  DateTimeColumn get endAt => dateTime().nullable()();
  /// Опциональная заметка
  TextColumn get note => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Статусы задач
enum TaskStatus {
  active,
  done,
  archived,
}

/// Типы правил повторения
enum RepeatType {
  none,
  fixedSchedule,     // дни недели
  xTimesInNDays,     // X раз за N дней
  everyNDaysAfterCompletion, // каждые N дней после выполнения
}

/// Таблица задач
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  /// Статус: active, done, archived
  IntColumn get status => intEnum<TaskStatus>()();
  /// Дедлайн (опционально)
  DateTimeColumn get deadline => dateTime().nullable()();
  
  // Правило повторения
  IntColumn get repeatType => intEnum<RepeatType>().withDefault(const Constant(0))();
  /// JSON для хранения параметров повторения (дни недели, X, N)
  TextColumn get repeatParams => text().nullable()();
  
  /// Snooze до указанной даты
  DateTimeColumn get snoozeUntil => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Таблица истории выполнений для повторяющихся задач
class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text().references(Tasks, #id)();
  DateTimeColumn get completedAt => dateTime()();
}

@DriftDatabase(
  tables: [ActivityTypes, Sessions, Tasks, TaskCompletions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============================================================
  // Session Queries
  // ============================================================
  
  /// Получить активную сессию (где endAt = null)
  Stream<Session?> watchActiveSession() {
    return (select(sessions)
          ..where((s) => s.endAt.isNull())
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Получить сессии за период с join на activity_types
  Stream<List<SessionWithActivityType>> watchSessionsForPeriod({
    required DateTime from,
    required DateTime to,
  }) {
    final query = select(sessions).join([
      leftOuterJoin(activityTypes, activityTypes.id.equalsExp(sessions.activityTypeId)),
    ])
      ..where(sessions.startAt.isBiggerOrEqualValue(from) & sessions.startAt.isSmallerThanValue(to))
      ..orderBy([OrderingTerm.asc(sessions.startAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return SessionWithActivityType(
          session: row.readTable(sessions),
          activityType: row.readTableOrNull(activityTypes),
        );
      }).toList();
    });
  }

  /// Детекция конфликтов: найти сессии, которые пересекаются с candidateStart-candidateEnd
  Future<List<Session>> detectConflicts({
    required DateTime candidateStart,
    required DateTime candidateEnd,
    String? excludeSessionId, // Для редактирования существующей сессии
  }) {
    final query = select(sessions)
      ..where((s) {
        // Пересечение: (s.startAt < candidateEnd) AND ((s.endAt > candidateStart) OR (s.endAt IS NULL))
        // Если endAt is null -> сессия активна (бесконечна в будущем), значит она пересекается
        // с любой сессией, которая начинается после её начала (candidateStart < infinity)
        
        final sessionEndIsNull = s.endAt.isNull();
        final sessionEndIsAfterCandidateStart = s.endAt.isBiggerThanValue(candidateStart);
        
        final overlap = s.startAt.isSmallerThanValue(candidateEnd) & 
                        (sessionEndIsAfterCandidateStart | sessionEndIsNull);
        
        if (excludeSessionId != null) {
          return overlap & s.id.equals(excludeSessionId).not();
        }
        return overlap;
      });
    
    return query.get();
  }

  /// Получить все сессии за конкретный день
  Future<List<Session>> getSessionsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(sessions)
          ..where((s) => 
              s.startAt.isBiggerOrEqualValue(startOfDay) & 
              s.startAt.isSmallerThanValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.asc(s.startAt)]))
        .get();
  }

  // ============================================================
  // Activity Type Queries
  // ============================================================
  
  Stream<List<ActivityType>> watchActivityTypes() {
    return (select(activityTypes)
          ..orderBy([(a) => OrderingTerm.asc(a.order)]))
        .watch();
  }

  Future<int> createActivityType(ActivityTypesCompanion activityType) {
    return into(activityTypes).insert(activityType);
  }

  Future<bool> updateActivityType(ActivityType activityType) {
    return update(activityTypes).replace(activityType);
  }

  Future<int> deleteActivityType(String id) {
    return (delete(activityTypes)..where((a) => a.id.equals(id))).go();
  }

  // ============================================================
  // Task Queries
  // ============================================================

  Stream<List<Task>> watchTasksByStatus(TaskStatus? status) {
    if (status == null) {
      return select(tasks).watch();
    }
    return (select(tasks)..where((t) => t.status.equalsValue(status))).watch();
  }

  Future<List<Task>> getOverdueTasks() {
    final now = DateTime.now();
    return (select(tasks)
          ..where((t) => 
              t.status.equalsValue(TaskStatus.active) & 
              t.deadline.isNotNull() & 
              t.deadline.isSmallerThanValue(now)))
        .get();
  }

  Future<int> createTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(Task task) {
    return update(tasks).replace(task);
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // ============================================================
  // Session CRUD
  // ============================================================

  Future<int> createSession(SessionsCompanion session) {
    return into(sessions).insert(session);
  }

  Future<bool> updateSession(Session session) {
    return update(sessions).replace(session);
  }

  Future<int> deleteSession(String id) {
    return (delete(sessions)..where((s) => s.id.equals(id))).go();
  }

  /// Остановить активную сессию
  Future<void> stopActiveSession(DateTime endTime) async {
    final activeSession = await watchActiveSession().first;
    if (activeSession != null) {
      await (update(sessions)..where((s) => s.id.equals(activeSession.id)))
          .write(SessionsCompanion(endAt: Value(endTime)));
    }
  }
}

/// Value class для сессии с информацией о типе активности
class SessionWithActivityType {
  final Session session;
  final ActivityType? activityType;

  SessionWithActivityType({
    required this.session,
    required this.activityType,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tempo_db.sqlite'));
    return NativeDatabase(file);
  });
}
