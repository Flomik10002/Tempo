import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// --- Таблицы ---

// Активности (Code, Gym, Sleep)
class ActivityTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text()(); // Hex string like "FF0000"
  IntColumn get order => integer().withDefault(const Constant(0))();
}

// Сессии таймера (История)
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId => integer().references(ActivityTypes, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()(); // Null = таймер идет сейчас
}

// Задачи (ToDo)
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Сама База Данных ---

@DriftDatabase(tables: [ActivityTypes, Sessions, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Начальное заполнение данными (Seeding)
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Дефолтные активности
      await into(activityTypes).insert(ActivityTypesCompanion.insert(name: 'Work', color: '0xFF007AFF', order: 0));
      await into(activityTypes).insert(ActivityTypesCompanion.insert(name: 'Gym', color: '0xFFFF2D55', order: 1));
      await into(activityTypes).insert(ActivityTypesCompanion.insert(name: 'Study', color: '0xFFFFCC00', order: 2));
      await into(activityTypes).insert(ActivityTypesCompanion.insert(name: 'Rest', color: '0xFF34C759', order: 3));
    },
  );
}

// --- Подключение (iOS Fix included) ---
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // На iOS используем Library directory для стабильности
    final dbFolder = await getApplicationLibraryDirectory();
    final file = File(p.join(dbFolder.path, 'tempo_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}