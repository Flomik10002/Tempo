import 'package:drift/drift.dart';
import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/conflict_resolution.dart';
import 'package:tempo/src/domain/repositories/session_repository.dart';
import 'package:uuid/uuid.dart';

class SessionRepositoryImpl implements SessionRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SessionRepositoryImpl(this._db);

  @override
  Stream<Session?> watchActiveSession() {
    return _db.watchActiveSession();
  }

  @override
  Stream<List<SessionWithActivityType>> watchSessionsForPeriod({
    required DateTime from,
    required DateTime to,
  }) {
    return _db.watchSessionsForPeriod(from: from, to: to);
  }

  @override
  Future<List<Session>> getSessionsForDay(DateTime day) {
    return _db.getSessionsForDay(day);
  }

  @override
  Future<void> createSession({
    required String activityTypeId,
    required DateTime startAt,
    DateTime? endAt,
    String? note,
  }) async {
    final session = SessionsCompanion(
      id: Value(_uuid.v4()),
      activityTypeId: Value(activityTypeId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      note: Value(note),
    );

    await _db.createSession(session);
  }

  @override
  Future<void> updateSession(Session session) {
    return _db.updateSession(session);
  }

  @override
  Future<void> deleteSession(String id) {
    return _db.deleteSession(id);
  }

  @override
  Future<void> startSession(String activityTypeId) async {
    // Закрыть активную сессию если есть
    await stopActiveSession();

    // Создать новую сессию
    await createSession(
      activityTypeId: activityTypeId,
      startAt: DateTime.now(),
    );
  }

  @override
  Future<void> stopActiveSession() async {
    await _db.stopActiveSession(DateTime.now());
  }

  @override
  Future<void> switchSession(String newActivityTypeId) async {
    final now = DateTime.now();
    
    // Закрыть текущую сессию
    await _db.stopActiveSession(now);
    
    // Сразу открыть новую
    await createSession(
      activityTypeId: newActivityTypeId,
      startAt: now,
    );
  }

  @override
  Future<List<SessionConflict>> detectConflicts({
    required DateTime candidateStart,
    required DateTime candidateEnd,
    required String candidateActivityName,
    String? excludeSessionId,
  }) async {
    final conflictingSessions = await _db.detectConflicts(
      candidateStart: candidateStart,
      candidateEnd: candidateEnd,
      excludeSessionId: excludeSessionId,
    );

    // Получить ActivityType для каждой конфликтующей сессии
    final conflicts = <SessionConflict>[];
    
    for (final session in conflictingSessions) {
      // Query activity type для получения имени
      final query = _db.select(_db.activityTypes)
        ..where((a) => a.id.equals(session.activityTypeId));
      final activityType = await query.getSingleOrNull();
      
      if (activityType != null) {
        conflicts.add(SessionConflict(
          existingSessionId: session.id,
          existingActivityName: activityType.name,
          existingStart: session.startAt,
          existingEnd: session.endAt,
          candidateStart: candidateStart,
          candidateEnd: candidateEnd,
          candidateActivityName: candidateActivityName,
        ));
      }
    }

    return conflicts;
  }

  @override
  Future<void> resolveConflict({
    required SessionConflict conflict,
    required ConflictResolutionStrategy strategy,
    required String newActivityTypeId,
    DateTime? newStartAt,
    DateTime? newEndAt,
    String? note,
  }) async {
    switch (strategy) {
      case ConflictResolutionStrategy.trimPrevious:
        // Обрезать существующую сессию - установить endAt = candidateStart
        final query = _db.select(_db.sessions)
          ..where((s) => s.id.equals(conflict.existingSessionId));
        final existingSession = await query.getSingle();
        
        await _db.updateSession(
          existingSession.copyWith(endAt: Value(conflict.candidateStart)),
        );
        
        // Создать новую сессию
        await createSession(
          activityTypeId: newActivityTypeId,
          startAt: newStartAt ?? conflict.candidateStart,
          endAt: newEndAt,
          note: note,
        );
        break;

      case ConflictResolutionStrategy.trimNew:
        // Обрезать новую сессию - начать после окончания существующей
        final trimmedStart = conflict.existingEnd ?? DateTime.now();
        if (trimmedStart.isBefore(newEndAt ?? conflict.candidateEnd)) {
          await createSession(
            activityTypeId: newActivityTypeId,
            startAt: trimmedStart,
            endAt: newEndAt,
            note: note,
          );
        }
        break;

      case ConflictResolutionStrategy.splitPrevious:
        // Разрезать существующую сессию на две части
        final query = _db.select(_db.sessions)
          ..where((s) => s.id.equals(conflict.existingSessionId));
        final existingSession = await query.getSingle();
        
        // Первая часть: от оригинального start до candidateStart
        await _db.updateSession(
          existingSession.copyWith(endAt: Value(conflict.candidateStart)),
        );
        
        // Вторая часть: от candidateEnd до оригинального end
        if (conflict.existingEnd != null && 
            conflict.candidateEnd.isBefore(conflict.existingEnd!)) {
          await createSession(
            activityTypeId: existingSession.activityTypeId,
            startAt: conflict.candidateEnd,
            endAt: conflict.existingEnd,
            note: existingSession.note,
          );
        }
        
        // Создать новую сессию посередине
        await createSession(
          activityTypeId: newActivityTypeId,
          startAt: newStartAt ?? conflict.candidateStart,
          endAt: newEndAt ?? conflict.candidateEnd,
          note: note,
        );
        break;

      case ConflictResolutionStrategy.cancel:
        // Ничего не делать
        break;
    }
  }
}
