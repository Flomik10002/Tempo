import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';

class ReorderActivityTypesUseCase {
  final ActivityTypeRepository _repository;

  ReorderActivityTypesUseCase(this._repository);

  Future<void> call(List<String> orderedIds) async {
    await _repository.reorderActivityTypes(orderedIds);
  }
}
