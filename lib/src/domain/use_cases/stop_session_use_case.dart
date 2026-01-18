import 'package:tempo/src/domain/repositories/session_repository.dart';

/// Use case для остановки активной сессии
class StopSessionUseCase {
  final SessionRepository _repository;

  StopSessionUseCase(this._repository);

  /// Остановить текущую активную сессию
  Future<void> call() async {
    await _repository.stopActiveSession();
  }
}
