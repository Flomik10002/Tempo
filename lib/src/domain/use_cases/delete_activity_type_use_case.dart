import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';

class DeleteActivityTypeUseCase {
  final ActivityTypeRepository _repository;

  DeleteActivityTypeUseCase(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteActivityType(id);
  }
}
