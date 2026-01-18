import 'package:tempo/src/domain/repositories/task_repository.dart';

/// Use case для отметки задачи как выполненной
class CompleteTaskUseCase {
  final TaskRepository _repository;

  CompleteTaskUseCase(this._repository);

  /// Отметить задачу выполненной
  /// Автоматически создается следующий экземпляр для повторяющихся задач
  Future<void> call(String taskId) async {
    await _repository.completeTask(taskId);
  }
}
