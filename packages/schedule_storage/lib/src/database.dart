import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class ScheduleDatabase extends _$ScheduleDatabase {
  ScheduleDatabase(super.executor);
  ScheduleDatabase.memory() : super(NativeDatabase.memory());
  ScheduleDatabase.file(File file)
    : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 1 || to != 6) {
        throw StateError('No migration registered from $from to $to');
      }
      if (from < 2) await m.createTable(classDaysOff);
      if (from < 3) await m.createTable(classDayReplacements);
      if (from < 4) await m.createTable(lessonTransfers);
      if (from < 5) await m.createTable(courseScheduleTimes);
      if (from < 6) {
        await m.alterTable(TableMigration(taskEvents));
        await m.createTable(lessonTransferEdits);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      final violations = await customSelect('PRAGMA foreign_key_check').get();
      if (violations.isNotEmpty) {
        throw StateError('Database has foreign key violations');
      }
    },
  );
}
