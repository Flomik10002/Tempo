import 'package:tempo/src/domain/repositories/session_repository.dart';

/// Use case для переключения на другую активность
class SwitchSessionUseCase {
  final SessionRepository _repository;

  SwitchSessionUseCase(this._repository);

  /// Переключиться на другую активность
  /// Атомарно закрывает текущую и открывает новую
  Future<void> call(String newActivityTypeId) async {
    await _repository.switchSession(newActivityTypeId);
  }
}
