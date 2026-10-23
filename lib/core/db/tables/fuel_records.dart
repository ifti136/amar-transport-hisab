import 'package:drift/drift.dart';
import 'vehicles.dart';
import 'expenses.dart';

class FuelRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  IntColumn get expenseId => integer().references(Expenses, #id)(); // links to diesel expense
  RealColumn get litres => real()(); // 1 decimal precision
  IntColumn get ratePerLitrePaisa => integer()();
  IntColumn get odometer => integer()();
  DateTimeColumn get fuelDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}