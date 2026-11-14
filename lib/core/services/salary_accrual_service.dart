import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/tables/driver_transactions.dart';
import '../db/daos/driver_dao.dart';
import '../db/daos/driver_loan_dao.dart';

/// Service to handle monthly salary accrual for drivers
/// Called on app start and when date changes to ensure salaries are accrued
class SalaryAccrualService {
  final AppDatabase db;
  final DriverDao driverDao;
  final DriverTransactionDao transactionDao;

  SalaryAccrualService(this.db, this.driverDao, this.transactionDao);

  /// Ensure monthly salary is accrued for all active drivers
  /// Called on app start and when date changes
  Future<void> ensureMonthlySalaryAccrued() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    // Get all active drivers
    final drivers = await driverDao.getActiveDrivers();

    for (final driver in drivers) {
      // Check if driver joined before or during current month
      final joinedMonth = DateTime(driver.joinedDate.year, driver.joinedDate.month);
      if (joinedMonth.isAfter(currentMonth)) {
        // Driver joins in future month, skip
        continue;
      }

      await _accrueIfMissing(driver, currentMonth);
    }
  }

  /// Accrue salary only when the month has no salary_earned row.
  ///
  /// The check and insert run in one transaction so two concurrent triggers
  /// (startup + resume) cannot both insert.
  Future<void> _accrueIfMissing(Driver driver, DateTime month) async {
    await db.transaction(() async {
      final exists =
          await transactionDao.hasSalaryEarnedForMonth(driver.id, month);
      if (exists) return;

      await transactionDao.insertWithAudit(
        DriverTransactionsCompanion.insert(
          driverId: driver.id,
          type: 'salary_earned',
          amountPaisa: driver.monthlySalaryPaisa,
          transactionDate: month,
          note: Value('Monthly salary accrual for ${month.year}-${month.month.toString().padLeft(2, '0')}'),
        ),
        userNote: 'Monthly salary accrual',
      );
    });
  }

  /// Accrue salary for a specific driver and month (manual trigger)
  Future<void> accrueSalaryForMonth(int driverId, DateTime month) async {
    final driver = await driverDao.getById(driverId);
    if (driver == null) return;

    await _accrueIfMissing(driver, month);
  }

  /// Get total salary earned for a driver up to a date
  Future<int> getTotalSalaryEarned(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('salary_earned') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();

    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  /// Get total salary paid for a driver up to a date
  Future<int> getTotalSalaryPaid(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('salary_paid') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();

    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  /// Get total advances given for a driver up to a date
  Future<int> getTotalAdvancesGiven(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('advance_given') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();

    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  /// Get total advances deducted for a driver up to a date
  Future<int> getTotalAdvancesDeducted(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('advance_deducted') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();

    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  /// Get driver balance up to a date
  /// Balance = salary_earned - salary_paid - advance_given + advance_deducted + loan_given - loan_repaid
  Future<int> getDriverBalance(int driverId, DateTime upTo) async {
    final salaryEarned = await getTotalSalaryEarned(driverId, upTo);
    final salaryPaid = await getTotalSalaryPaid(driverId, upTo);
    final advancesGiven = await getTotalAdvancesGiven(driverId, upTo);
    final advancesDeducted = await getTotalAdvancesDeducted(driverId, upTo);

    // Loans
    final loansGiven = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('loan_given') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();
    final loansRepaid = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('loan_repaid') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();

    final totalLoansGiven = loansGiven.fold(0, (sum, t) => sum + t.amountPaisa);
    final totalLoansRepaid = loansRepaid.fold(0, (sum, t) => sum + t.amountPaisa);

    return salaryEarned - salaryPaid - advancesGiven + advancesDeducted + totalLoansGiven - totalLoansRepaid;
  }

  /// Get outstanding advance for a driver (advance_given - advance_deducted)
  Future<int> getOutstandingAdvance(int driverId, DateTime upTo) async {
    final advancesGiven = await getTotalAdvancesGiven(driverId, upTo);
    final advancesDeducted = await getTotalAdvancesDeducted(driverId, upTo);
    return advancesGiven - advancesDeducted;
  }
}