import 'package:tempo/src/domain/repositories/session_repository.dart';

/// Use case для запуска новой сессии активности
class StartSessionUseCase {
  final SessionRepository _repository;

  StartSessionUseCase(this._repository);

  /// Запустить новую сессию
  /// Автоматически закрывает активную сессию если есть
  Future<void> call(String activityTypeId) async {
    await _repository.startSession(activityTypeId);
  }
}
