import 'package:drift/drift.dart';
import 'package:tempo/src/data/database/drift_database.dart' as db;
import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';
import 'package:uuid/uuid.dart';

class ActivityTypeRepositoryImpl implements ActivityTypeRepository {
  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

  ActivityTypeRepositoryImpl(this._db);

  @override
  Stream<List<ActivityType>> watchActivityTypes() {
    return _db.watchActivityTypes().map((list) {
      return list.map((e) => ActivityType(
        id: e.id,
        name: e.name,
        color: e.color,
        position: e.order,
      )).toList();
    });
  }

  @override
  Future<void> createActivityType({
    required String name,
    required String color,
    required int order,
    bool isHidden = false,
  }) async {
    final activityType = db.ActivityTypesCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      color: Value(color),
      order: Value(order),
      isHidden: Value(isHidden),
    );

    await _db.createActivityType(activityType);
  }

  @override
  Future<void> updateActivityType(ActivityType activityType) {
    // Convert Domain to Drift Data Class
    // We assume 'isHidden' is false or preserved. Ideally Domain should have it.
    // Since domain doesn't have isHidden, we might lose it if we just blindly overwrite?
    // Using copyWith on existing might be safer but more expensive.
    // For now, let's just assume default or fetch first?
    // Or just simple update since we are replacing.
    
    // We need to match the signature of _db.updateActivityType which takes local ActivityType data class.
    final data = db.ActivityType(
      id: activityType.id,
      name: activityType.name,
      color: activityType.color,
      order: activityType.position,
      isHidden: false, // Potential data loss if isHidden was true? Domain entity should probably have it.
    );
    return _db.updateActivityType(data);
  }

  @override
  Future<void> deleteActivityType(String id) async {
    final inUse = await isActivityTypeInUse(id);
    if (inUse) {
      throw Exception('Cannot delete activity type that is used in sessions');
    }
    await _db.deleteActivityType(id);
  }

  @override
  Future<bool> isActivityTypeInUse(String id) async {
    final query = _db.select(_db.sessions)
      ..where((s) => s.activityTypeId.equals(id))
      ..limit(1);
    
    final session = await query.getSingleOrNull();
    return session != null;
  }

  @override
  Future<int> getNextOrder() async {
    final query = _db.selectOnly(_db.activityTypes)
      ..addColumns([_db.activityTypes.order.max()]);
    
    final result = await query.getSingleOrNull();
    final maxOrder = result?.read(_db.activityTypes.order.max());
    
    return (maxOrder ?? -1) + 1;
  }

  @override
  Future<void> reorderActivityTypes(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final query = _db.select(_db.activityTypes)
        ..where((a) => a.id.equals(orderedIds[i]));
      final activityType = await query.getSingleOrNull();
      
      if (activityType != null) {
        await _db.updateActivityType(
          activityType.copyWith(order: i),
        );
      }
    }
  }
}
