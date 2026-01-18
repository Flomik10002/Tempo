import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';

class CreateActivityTypeUseCase {
  final ActivityTypeRepository _repository;

  CreateActivityTypeUseCase(this._repository);

  Future<void> call(String name, String color) async {
    // Generate ID? Repository might handle it or we do it here. 
    // Drift ID is usually int autoincrement unless defined as String.
    // In db code it was text id.
    // Let's generate uuid? Or let repo handle if it takes entity.
    // Repo takes ActivityType.
    // I need uuid generator.
    final id = DateTime.now().millisecondsSinceEpoch.toString(); // Simple ID for now
    await _repository.createActivityType(
      name: name,
      color: color,
      order: 0, // Default order
    );
  }
}
