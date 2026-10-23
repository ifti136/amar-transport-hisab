import 'package:drift/drift.dart';
import 'vehicles.dart';

class VehicleLoans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  IntColumn get principalPaisa => integer()();
  IntColumn get annualInterestRateBps => integer()(); // basis points: 1200 = 12%
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}