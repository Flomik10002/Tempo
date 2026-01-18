import 'package:tempo/src/domain/entities/activity_type.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';

class UpdateActivityTypeUseCase {
  final ActivityTypeRepository _repository;

  UpdateActivityTypeUseCase(this._repository);

  Future<void> call(ActivityType activityType) async {
    await _repository.updateActivityType(activityType);
  }
}
