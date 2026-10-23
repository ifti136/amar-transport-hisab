import 'package:drift/drift.dart';

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().named('table_name')();
  IntColumn get rowId => integer()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get action => text()(); // insert, update, delete, soft_delete
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userNote => text().nullable()();

}