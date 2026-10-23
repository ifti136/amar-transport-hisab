import 'package:drift/drift.dart';
import 'drivers.dart';

class DriverTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get driverId => integer().references(Drivers, #id)();
  TextColumn get type => text()(); // salary_earned, salary_paid, advance_given, advance_deducted, loan_given, loan_repaid
  IntColumn get amountPaisa => integer()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}