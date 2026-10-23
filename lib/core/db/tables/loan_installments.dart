import 'package:drift/drift.dart';
import 'vehicle_loans.dart';

class LoanInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer().references(VehicleLoans, #id)();
  DateTimeColumn get installmentDate => dateTime()();
  IntColumn get totalPaidPaisa => integer()();
  IntColumn get principalPortionPaisa => integer()();
  IntColumn get interestPortionPaisa => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}