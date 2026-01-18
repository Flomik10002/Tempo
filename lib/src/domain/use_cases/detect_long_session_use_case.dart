import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/repositories/session_repository.dart';

/// Use case для детекции "забытых" длинных сессий
class DetectLongSessionUseCase {
  final SessionRepository _repository;
  
  /// Порог в часах для уведомления
  final int thresholdHours;

  DetectLongSessionUseCase(
    this._repository, {
    this.thresholdHours = 8,
  });

  /// Проверить активную сессию на длительность
  /// Возвращает активную сессию если она превышает порог, иначе null
  Future<Session?> call() async {
    final activeSession = await _repository.watchActiveSession().first;
    
    if (activeSession == null) {
      return null;
    }

    final duration = DateTime.now().difference(activeSession.startAt);
    
    if (duration.inHours >= thresholdHours) {
      return activeSession;
    }

    return null;
  }
}
