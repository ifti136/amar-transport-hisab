import 'package:drift/drift.dart';

class Drivers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  IntColumn get monthlySalaryPaisa => integer()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, inactive
  DateTimeColumn get joinedDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}