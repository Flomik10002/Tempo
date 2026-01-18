import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/conflict_resolution.dart';

/// Интерфейс репозитория для работы с сессиями активности
abstract class SessionRepository {
  /// Получить активную сессию (Stream для реактивности)
  Stream<Session?> watchActiveSession();
  
  /// Получить сессии за период
  Stream<List<SessionWithActivityType>> watchSessionsForPeriod({
    required DateTime from,
    required DateTime to,
  });
  
  /// Получить сессии за конкретный день
  Future<List<Session>> getSessionsForDay(DateTime day);
  
  /// Создать новую сессию
  Future<void> createSession({
    required String activityTypeId,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  });
  
  /// Обновить существующую сессию
  Future<void> updateSession(Session session);
  
  /// Удалить сессию
  Future<void> deleteSession(String id);
  
  /// Запустить новую сессию (закрыть текущую если есть)
  Future<void> startSession(String activityTypeId);
  
  /// Остановить активную сессию
  Future<void> stopActiveSession();
  
  /// Переключиться на другую активность (закрыть текущую, открыть новую)
  Future<void> switchSession(String newActivityTypeId);
  
  /// Детекция конфликтов с существующими сессиями
  Future<List<SessionConflict>> detectConflicts({
    required DateTime candidateStart,
    required DateTime candidateEnd,
    required String candidateActivityName,
    String? excludeSessionId,
  });
  
  /// Разрешить конфликт с выбранной стратегией
  Future<void> resolveConflict({
    required SessionConflict conflict,
    required ConflictResolutionStrategy strategy,
    required String newActivityTypeId,
    DateTime? newStartAt,
    DateTime? newEndAt,
    String? note,
  });
}
