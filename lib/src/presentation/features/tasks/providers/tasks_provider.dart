import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Provider для списка задач с фильтрацией по статусу
final tasksByStatusProvider = StreamProvider.family<List<Task>, TaskStatus?>((ref, status) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByStatus(status);
});

/// Provider для всех задач (без фильтра)
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByStatus(null);
});
