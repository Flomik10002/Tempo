import 'dart:convert';

/// Базовый класс для правил повторения задач
sealed class RepeatRule {
  const RepeatRule();
  
  /// Сериализация в JSON string для хранения в БД
  String toJson();
  
  /// Десериализация из JSON string
  static RepeatRule fromJson(String json, int type) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    
    return switch (type) {
      1 => FixedScheduleRepeat.fromMap(map),
      2 => XTimesInNDaysRepeat.fromMap(map),
      3 => EveryNDaysAfterCompletionRepeat.fromMap(map),
      _ => throw ArgumentError('Unknown repeat type: $type'),
    };
  }
}

/// Повторение по фиксированному расписанию (дни недели)
class FixedScheduleRepeat extends RepeatRule {
  /// Дни недели: 1=понедельник, 7=воскресенье
  final Set<int> weekdays;

  const FixedScheduleRepeat(this.weekdays);

  factory FixedScheduleRepeat.fromMap(Map<String, dynamic> map) {
    return FixedScheduleRepeat(
      (map['weekdays'] as List).cast<int>().toSet(),
    );
  }

  @override
  String toJson() {
    return jsonEncode({
      'weekdays': weekdays.toList(),
    });
  }

  /// Проверить, попадает ли дата на один из выбранных дней недели
  bool matchesDate(DateTime date) {
    return weekdays.contains(date.weekday);
  }
}

/// Повторение X раз за N дней (ключевой режим из ТЗ)
class XTimesInNDaysRepeat extends RepeatRule {
  /// Количество раз
  final int times;
  
  /// Количество дней
  final int days;

  const XTimesInNDaysRepeat({
    required this.times,
    required this.days,
  });

  factory XTimesInNDaysRepeat.fromMap(Map<String, dynamic> map) {
    return XTimesInNDaysRepeat(
      times: map['times'] as int,
      days: map['days'] as int,
    );
  }

  @override
  String toJson() {
    return jsonEncode({
      'times': times,
      'days': days,
    });
  }
}

/// Повторение каждые N дней после выполнения
class EveryNDaysAfterCompletionRepeat extends RepeatRule {
  /// Количество дней
  final int days;

  const EveryNDaysAfterCompletionRepeat(this.days);

  factory EveryNDaysAfterCompletionRepeat.fromMap(Map<String, dynamic> map) {
    return EveryNDaysAfterCompletionRepeat(map['days'] as int);
  }

  @override
  String toJson() {
    return jsonEncode({
      'days': days,
    });
  }

  /// Вычислить следующую дату по времени последнего выполнения
  DateTime nextOccurrence(DateTime completedAt) {
    return completedAt.add(Duration(days: days));
  }
}
