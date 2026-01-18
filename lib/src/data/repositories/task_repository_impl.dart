import 'package:drift/drift.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/repeat_rule.dart';
import 'package:tempo/src/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TaskRepositoryImpl(this._db);

  @override
  Stream<List<Task>> watchTasksByStatus(TaskStatus? status) {
    return _db.watchTasksByStatus(status);
  }

  @override
  Future<List<Task>> getOverdueTasks() {
    return _db.getOverdueTasks();
  }

  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    // Задачи с deadline на указанную дату или активные
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final query = _db.select(_db.tasks)
      ..where((t) => 
          (t.status.equalsValue(TaskStatus.active)) &
          ((t.deadline.isBiggerOrEqualValue(startOfDay) & 
            t.deadline.isSmallerThanValue(endOfDay)) |
           t.deadline.isNull())
      );
    
    return query.get();
  }

  @override
  Future<void> createTask({
    required String title,
    TaskStatus status = TaskStatus.active,
    DateTime? deadline,
    RepeatRule? repeatRule,
  }) async {
    final task = TasksCompanion(
      id: Value(_uuid.v4()),
      title: Value(title),
      status: Value(status),
      deadline: Value(deadline),
      repeatType: Value(_getRepeatType(repeatRule)),
      repeatParams: Value(repeatRule?.toJson()),
      createdAt: Value(DateTime.now()),
    );

    await _db.createTask(task);
  }

  @override
  Future<void> updateTask(Task task, {RepeatRule? repeatRule}) async {
    if (repeatRule != null) {
      final updatedTask = task.copyWith(
        repeatType: _getRepeatType(repeatRule),
        repeatParams: Value(repeatRule.toJson()),
      );
      await _db.updateTask(updatedTask);
    } else {
      await _db.updateTask(task);
    }
  }

  @override
  Future<void> completeTask(String taskId) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
    final task = await query.getSingle();
    
    // Сохранить выполнение в истории
    await _db.into(_db.taskCompletions).insert(
      TaskCompletionsCompanion(
        taskId: Value(taskId),
        completedAt: Value(DateTime.now()),
      ),
    );

    // Если задача повторяющаяся - создать следующий экземпляр
    if (task.repeatType != RepeatType.none && task.repeatParams != null) {
      await _generateNextTask(task);
    }
    
    // Обновить статус на done
    await _db.updateTask(task.copyWith(status: TaskStatus.done));
  }

  @override
  Future<void> snoozeTask(String taskId, DateTime until) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
    final task = await query.getSingle();
    
    await _db.updateTask(task.copyWith(snoozeUntil: Value(until)));
  }

  @override
  Future<void> rescheduleTask(String taskId, DateTime newDeadline) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
    final task = await query.getSingle();
    
    await _db.updateTask(task.copyWith(deadline: Value(newDeadline)));
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _db.deleteTask(taskId);
  }

  @override
  Future<void> archiveTask(String taskId) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
    final task = await query.getSingle();
    
    await _db.updateTask(task.copyWith(status: TaskStatus.archived));
  }

  @override
  Future<int> getCompletionCount(String taskId, DateTime from, DateTime to) async {
    final query = _db.select(_db.taskCompletions)
      ..where((tc) => 
          tc.taskId.equals(taskId) &
          tc.completedAt.isBiggerOrEqualValue(from) &
          tc.completedAt.isSmallerThanValue(to)
      );
    
    final completions = await query.get();
    return completions.length;
  }

  @override
  Future<RepeatRule?> getRepeatRule(String taskId) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
    final task = await query.getSingle();
    
    if (task.repeatType == RepeatType.none || task.repeatParams == null) {
      return null;
    }
    
    return RepeatRule.fromJson(
      task.repeatParams!,
      task.repeatType.index,
    );
  }

  // ============================================================
  // Private helpers
  // ============================================================

  RepeatType _getRepeatType(RepeatRule? rule) {
    if (rule == null) return RepeatType.none;
    
    return switch (rule) {
      FixedScheduleRepeat() => RepeatType.fixedSchedule,
      XTimesInNDaysRepeat() => RepeatType.xTimesInNDays,
      EveryNDaysAfterCompletionRepeat() => RepeatType.everyNDaysAfterCompletion,
    };
  }

  Future<void> _generateNextTask(Task completedTask) async {
    final repeatRule = await getRepeatRule(completedTask.id);
    if (repeatRule == null) return;

    DateTime? nextDeadline;
    final now = DateTime.now();

    switch (repeatRule) {
      case FixedScheduleRepeat(:final weekdays):
        // Найти следующий день недели из списка
        DateTime candidate = now.add(const Duration(days: 1));
        while (!weekdays.contains(candidate.weekday)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        nextDeadline = candidate;
        break;

      case XTimesInNDaysRepeat(:final times, :final days):
        // Для X раз за N дней - просто создаем задачу без deadline
        // Логика подсчета будет в UI через getCompletionCount
        nextDeadline = null;
        break;

      case EveryNDaysAfterCompletionRepeat(:final days):
        nextDeadline = now.add(Duration(days: days));
        break;
    }

    // Создать новую задачу с тем же title и repeatRule
    await createTask(
      title: completedTask.title,
      deadline: nextDeadline,
      repeatRule: repeatRule,
    );
  }
}
