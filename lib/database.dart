import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// --- Tables ---

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text()(); // Hex 0xFF...
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  // CASCADE: Если удалить активность, удалится и история (чтобы не было ошибок)
  IntColumn get activityId => integer().references(Activities, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isRepeating => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
}

// --- Database ---

@DriftDatabase(tables: [Activities, Sessions, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Default Data
      await into(activities).insert(ActivitiesCompanion.insert(name: 'Coding', color: '0xFF007AFF', sortOrder: const Value(0)));
      await into(activities).insert(ActivitiesCompanion.insert(name: 'Sport', color: '0xFF34C759', sortOrder: const Value(2)));
      await into(activities).insert(ActivitiesCompanion.insert(name: 'Rest', color: '0xFFFF9500', sortOrder: const Value(3)));
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Здесь в будущем будем описывать миграции (например, добавление колонок),
      // чтобы данные не терялись при обновлении версии schemaVersion.
    },
    beforeOpen: (details) async {
      // Включаем каскадное удаление (SQLite foreign keys)
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // Стабильное имя файла. Не меняй его в будущих версиях, если хочешь сохранить данные.
    final file = File(p.join(dbFolder.path, 'tempo_storage.sqlite'));
    return NativeDatabase(file);
  });
}