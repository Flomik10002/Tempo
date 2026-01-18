import 'package:drift/drift.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Хелпер для инициализации дефолтных типов активности
class DatabaseSeeder {
  final AppDatabase _db;

  DatabaseSeeder(this._db);

  /// Заполнить БД начальными данными если она пустая
  Future<void> seedIfEmpty() async {
    final existingTypes = await _db.select(_db.activityTypes).get();
    
    if (existingTypes.isNotEmpty) {
      return; // Уже есть данные
    }

    // Создать дефолтные типы активности
    final defaultTypes = [
      _activityType('Code', '#6366F1', 0),
      _activityType('Study', '#8B5CF6', 1),
      _activityType('Gym', '#EF4444', 2),
      _activityType('Sleep', '#3B82F6', 3),
      _activityType('Meeting', '#F59E0B', 4),
      _activityType('Design', '#EC4899', 5),
      _activityType('Reading', '#10B981', 6),
      _activityType('Break', '#94A3B8', 7),
    ];

    for (final type in defaultTypes) {
      await _db.into(_db.activityTypes).insert(type);
    }
  }

  ActivityTypesCompanion _activityType(String name, String color, int order) {
    return ActivityTypesCompanion(
      id: Value(_generateId(name)),
      name: Value(name),
      color: Value(color),
      order: Value(order),
      isHidden: const Value(false),
    );
  }

  String _generateId(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }
}
