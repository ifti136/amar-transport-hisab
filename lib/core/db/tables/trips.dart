import 'package:drift/drift.dart';
import 'vehicles.dart';
import 'drivers.dart';
import 'customers.dart';

class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  IntColumn get driverId => integer().references(Drivers, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get tripDate => dateTime()();
  IntColumn get agreedFarePaisa => integer()();
  IntColumn get advancePaisa => integer().withDefault(const Constant(0))();
  IntColumn get startOdo => integer()();
  IntColumn get endOdo => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))(); // completed, cancelled
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}