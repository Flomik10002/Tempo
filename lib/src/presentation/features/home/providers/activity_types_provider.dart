import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Provider для списка типов активности
final activityTypesProvider = StreamProvider<List<ActivityType>>((ref) {
  final repository = ref.watch(activityTypeRepositoryProvider);
  return repository.watchActivityTypes();
});

