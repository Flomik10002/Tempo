import 'package:tempo/src/domain/entities/repeat_rule.dart';
import 'package:tempo/src/domain/repositories/task_repository.dart';

/// Use case для создания новой задачи
class CreateTaskUseCase {
  final TaskRepository _repository;

  CreateTaskUseCase(this._repository);

  /// Создать новую задачу
  Future<void> call({
    required String title,
    DateTime? deadline,
    RepeatRule? repeatRule,
  }) async {
    await _repository.createTask(
      title: title,
      deadline: deadline,
      repeatRule: repeatRule,
    );
  }
}
