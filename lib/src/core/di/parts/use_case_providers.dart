import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/domain/use_cases/add_manual_session_use_case.dart';
import 'package:tempo/src/domain/use_cases/complete_task_use_case.dart';
import 'package:tempo/src/domain/use_cases/create_task_use_case.dart';
import 'package:tempo/src/domain/use_cases/detect_long_session_use_case.dart';
import 'package:tempo/src/domain/use_cases/create_activity_type_use_case.dart';
import 'package:tempo/src/domain/use_cases/delete_activity_type_use_case.dart';
import 'package:tempo/src/domain/use_cases/start_session_use_case.dart';
import 'package:tempo/src/domain/use_cases/stop_session_use_case.dart';
import 'package:tempo/src/domain/use_cases/switch_session_use_case.dart';
import 'package:tempo/src/domain/use_cases/update_activity_type_use_case.dart';
import 'package:tempo/src/domain/use_cases/reorder_activity_types_use_case.dart';

// ============================================================
// Session Use Cases
// ============================================================

final startSessionUseCaseProvider = Provider((ref) {
  return StartSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final stopSessionUseCaseProvider = Provider((ref) {
  return StopSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final switchSessionUseCaseProvider = Provider((ref) {
  return SwitchSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final addManualSessionUseCaseProvider = Provider((ref) {
  return AddManualSessionUseCase(
    ref.watch(sessionRepositoryProvider),
    ref.watch(activityTypeRepositoryProvider),
  );
});

final detectLongSessionUseCaseProvider = Provider((ref) {
  return DetectLongSessionUseCase(ref.watch(sessionRepositoryProvider));
});

// ============================================================
// Task Use Cases
// ============================================================

final createTaskUseCaseProvider = Provider((ref) {
  return CreateTaskUseCase(ref.watch(taskRepositoryProvider));
});

final completeTaskUseCaseProvider = Provider((ref) {
  return CompleteTaskUseCase(ref.watch(taskRepositoryProvider));
});

// ============================================================
// Activity Type Use Cases
// ============================================================

final createActivityTypeUseCaseProvider = Provider((ref) {
  return CreateActivityTypeUseCase(ref.watch(activityTypeRepositoryProvider));
});

final updateActivityTypeUseCaseProvider = Provider((ref) {
  return UpdateActivityTypeUseCase(ref.watch(activityTypeRepositoryProvider));
});

final deleteActivityTypeUseCaseProvider = Provider((ref) {
  return DeleteActivityTypeUseCase(ref.watch(activityTypeRepositoryProvider));
});

final reorderActivityTypesUseCaseProvider = Provider((ref) {
  // Need to import usecase if I can, but imports are at top. I'll rely on auto-fix or just add import in next step if it fails?
  // I should add import first.
  // Wait, I can't add import easily without full file write or another replace call at top.
  // I will assume simple name resolution won't work without import.
  // I will use write_to_file to overwrite the whole file or ...
  // Let's replace the top imports block first.
  return ReorderActivityTypesUseCase(ref.watch(activityTypeRepositoryProvider));
});

