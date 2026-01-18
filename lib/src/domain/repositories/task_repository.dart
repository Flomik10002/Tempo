import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/repeat_rule.dart';

/// Интерфейс репозитория для работы с задачами
abstract class TaskRepository {
  /// Получить задачи по статусу (Stream для реактивности)
  Stream<List<Task>> watchTasksByStatus(TaskStatus? status);
  
  /// Получить просроченные задачи
  Future<List<Task>> getOverdueTasks();
  
  /// Получить задачи на конкретную дату
  Future<List<Task>> getTasksForDate(DateTime date);
  
  /// Создать новую задачу
  Future<void> createTask({
    required String title,
    TaskStatus status = TaskStatus.active,
    DateTime? deadline,
    RepeatRule? repeatRule,
  });
  
  /// Обновить задачу
  Future<void> updateTask(Task task, {RepeatRule? repeatRule});
  
  /// Отметить задачу как выполненную
  /// Для повторяющихся - создается следующий экземпляр
  Future<void> completeTask(String taskId);
  
  /// Отложить задачу (snooze) до указанной даты
  Future<void> snoozeTask(String taskId, DateTime until);
  
  /// Перенести задачу на другую дату (изменить deadline)
  Future<void> rescheduleTask(String taskId, DateTime newDeadline);
  
  /// Удалить задачу
  Future<void> deleteTask(String taskId);
  
  /// Архивировать задачу
  Future<void> archiveTask(String taskId);
  
  /// Получить количество выполнений задачи за период (для XTimesInNDays)
  Future<int> getCompletionCount(String taskId, DateTime from, DateTime to);
  
  /// Получить правило повторения для задачи
  Future<RepeatRule?> getRepeatRule(String taskId);
}
