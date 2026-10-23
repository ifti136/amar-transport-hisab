import 'package:drift/drift.dart';
import 'vehicles.dart';
import 'trips.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  IntColumn get tripId => integer().nullable().references(Trips, #id)();
  TextColumn get category => text()(); // diesel, toll, repair, maintenance, insurance, fitness, tax_token, other
  IntColumn get amountPaisa => integer()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}