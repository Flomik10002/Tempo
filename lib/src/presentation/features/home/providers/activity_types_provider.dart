import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/domain/entities/activity_type.dart';

/// Provider для списка типов активности
final activityTypesProvider = StreamProvider<List<ActivityType>>((ref) {
  final repository = ref.watch(activityTypeRepositoryProvider);
  return repository.watchActivityTypes();
});

