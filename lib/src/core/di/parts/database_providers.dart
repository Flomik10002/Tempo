import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tempo/src/data/database/drift_database.dart';

part 'database_providers.g.dart';

/// Provider для Drift database instance
@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}
