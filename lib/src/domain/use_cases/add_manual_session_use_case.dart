import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/conflict_resolution.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';
import 'package:tempo/src/domain/repositories/session_repository.dart';

/// Результат добавления сессии вручную
sealed class AddManualSessionResult {
  bool get isSuccess => this is AddManualSessionSuccess;
  List<SessionConflict> get conflicts => 
      this is AddManualSessionConflict 
          ? (this as AddManualSessionConflict).conflicts 
          : [];
}

/// Успешно добавлено
class AddManualSessionSuccess extends AddManualSessionResult {}

/// Обнаружены конфликты - требуется разрешение
class AddManualSessionConflict extends AddManualSessionResult {
  final List<SessionConflict> conflicts;

  AddManualSessionConflict(this.conflicts);
}

/// Use case для добавления сессии вручную с проверкой конфликтов
class AddManualSessionUseCase {
  final SessionRepository _sessionRepository;
  final ActivityTypeRepository _activityTypeRepository;

  AddManualSessionUseCase(
    this._sessionRepository,
    this._activityTypeRepository,
  );

  /// Добавить сессию вручную
  /// Возвращает Success или Conflict если есть пересечения
  Future<AddManualSessionResult> call({
    required String activityTypeId,
    required DateTime startAt,
    required DateTime endAt,
    String? note,
  }) async {
    // Получить имя активности для отображения в конфликтах
    final activityTypes = await _activityTypeRepository.watchActivityTypes().first;
    final activityType = activityTypes.firstWhere((a) => a.id == activityTypeId);

    // Проверить конфликты
    final conflicts = await _sessionRepository.detectConflicts(
      candidateStart: startAt,
      candidateEnd: endAt,
      candidateActivityName: activityType.name,
    );

    if (conflicts.isNotEmpty) {
      return AddManualSessionConflict(conflicts);
    }

    // Нет конфликтов - создать сессию
    await _sessionRepository.createSession(
      activityTypeId: activityTypeId,
      startAt: startAt,
      endAt: endAt,
      note: note,
    );

    return AddManualSessionSuccess();
  }

  /// Разрешить конфликт и создать сессию
  Future<void> resolveAndCreate({
    required SessionConflict conflict,
    required ConflictResolutionStrategy strategy,
    required String activityTypeId,
    required DateTime startAt,
    required DateTime endAt,
    String? note,
  }) async {
    await _sessionRepository.resolveConflict(
      conflict: conflict,
      strategy: strategy,
      newActivityTypeId: activityTypeId,
      newStartAt: startAt,
      newEndAt: endAt,
      note: note,
    );
  }
}
