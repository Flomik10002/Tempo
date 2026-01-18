import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tempo/src/core/di/parts/database_providers.dart';
import 'package:tempo/src/data/repositories/activity_type_repository_impl.dart';
import 'package:tempo/src/data/repositories/session_repository_impl.dart';
import 'package:tempo/src/data/repositories/task_repository_impl.dart';
import 'package:tempo/src/domain/repositories/activity_type_repository.dart';
import 'package:tempo/src/domain/repositories/session_repository.dart';
import 'package:tempo/src/domain/repositories/task_repository.dart';

part 'repository_providers.g.dart';

/// Provider для SessionRepository
@riverpod
SessionRepository sessionRepository(SessionRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return SessionRepositoryImpl(db);
}

/// Provider для ActivityTypeRepository
@riverpod
ActivityTypeRepository activityTypeRepository(ActivityTypeRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return ActivityTypeRepositoryImpl(db);
}

/// Provider для TaskRepository
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskRepositoryImpl(db);
}
