import 'package:drift/drift.dart';

class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get regNo => text().withLength(min: 1, max: 20)();
  TextColumn get type => text().withDefault(const Constant('Covered Van'))();
  DateTimeColumn get insuranceExpiry => dateTime().nullable()();
  DateTimeColumn get fitnessExpiry => dateTime().nullable()();
  DateTimeColumn get taxExpiry => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, sold, retired
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}