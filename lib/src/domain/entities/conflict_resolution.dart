/// Стратегии разрешения конфликтов сессий
enum ConflictResolutionStrategy {
  /// Обрезать предыдущую сессию до начала новой 
  trimPrevious,
  
  /// Обрезать новую сессию до конца предыдущей
  trimNew,
  
  /// Разрезать предыдущую сессию вокруг новой
  /// (создать две части: до и после новой)
  splitPrevious,
  
  /// Отменить операцию
  cancel,
}

/// Описание конфликта между сессиями
class SessionConflict {
  /// ID существующей (конфликтующей) сессии
  final String existingSessionId;
  
  /// Название типа активности существующей сессии
  final String existingActivityName;
  
  /// Время начала существующей сессии
  final DateTime existingStart;
  
  /// Время окончания существующей сессии (null если активна)
  final DateTime? existingEnd;
  
  /// Время начала новой (кандидата) сессии
  final DateTime candidateStart;
  
  /// Время окончания новой сессии
  final DateTime candidateEnd;
  
  /// Название типа активности новой сессии
  final String candidateActivityName;

  const SessionConflict({
    required this.existingSessionId,
    required this.existingActivityName,
    required this.existingStart,
    this.existingEnd,
    required this.candidateStart,
    required this.candidateEnd,
    required this.candidateActivityName,
  });

  /// Вычислить продолжительность пересечения
  Duration get overlapDuration {
    final existingEndTime = existingEnd ?? candidateEnd;
    final overlapStart = existingStart.isAfter(candidateStart) 
        ? existingStart 
        : candidateStart;
    final overlapEnd = existingEndTime.isBefore(candidateEnd) 
        ? existingEndTime 
        : candidateEnd;
    
    return overlapEnd.difference(overlapStart);
  }
}
