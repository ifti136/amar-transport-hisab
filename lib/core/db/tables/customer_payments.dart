import 'package:drift/drift.dart';
import 'trips.dart';
import 'customers.dart';

class CustomerPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get amountPaisa => integer()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}