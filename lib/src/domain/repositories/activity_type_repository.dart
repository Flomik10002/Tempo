import 'package:tempo/src/data/database/drift_database.dart';

/// Интерфейс репозитория для работы с типами активности
abstract class ActivityTypeRepository {
  /// Получить все типы активности (Stream для реактивности)
  Stream<List<ActivityType>> watchActivityTypes();
  
  /// Создать новый тип активности
  Future<void> createActivityType({
    required String name,
    required String color,
    required int order,
    bool isHidden = false,
  });
  
  /// Обновить существующий тип
  Future<void> updateActivityType(ActivityType activityType);
  
  /// Удалить тип активности
  Future<void> deleteActivityType(String id);
  
  /// Проверить, используется ли тип в сессиях
  Future<bool> isActivityTypeInUse(String id);
  
  /// Получить следующий порядковый номер для нового типа
  Future<int> getNextOrder();
  
  /// Переупорядочить типы активности
  Future<void> reorderActivityTypes(List<String> orderedIds);
}
