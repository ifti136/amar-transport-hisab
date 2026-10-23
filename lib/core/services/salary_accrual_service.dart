import 'package:drift/drift.dart';
import '../db/database.dart';
import '../db/tables/driver_transactions.dart';
import '../db/daos/driver_dao.dart';
import '../formatters.dart';

/// Service to handle monthly salary accrual for drivers
/// Called on app start and when date changes to ensure salaries are accrued
class SalaryAccrualService {
  final AppDatabase db;
  final DriverDao driverDao;

  SalaryAccrualService(this.db, this.driverDao);

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

      // Check if salary_earned already exists for current month
      final exists = await driverDao.hasSalaryEarnedForMonth(driver.id, currentMonth);

      if (!exists) {
        // Accrue salary for this month
        await _accrueSalary(driver, currentMonth);
      }
    }
  }

  /// Accrue salary for a specific driver and month
  Future<void> _accrueSalary(Driver driver, DateTime month) async {
    await db.into(db.driverTransactions).insert(
      DriverTransactionsCompanion.insert(
        driverId: driver.id,
        type: 'salary_earned',
        amountPaisa: driver.monthlySalaryPaisa,
        transactionDate: month,
        note: Value('Monthly salary accrual for ${formatMonth(month)}'),
      ),
    );
  }

  /// Accrue salary for a specific driver and month (manual trigger)
  Future<void> accrueSalaryForMonth(int driverId, DateTime month) async {
    final driver = await driverDao.getById(driverId);
    if (driver == null) return;

    final exists = await driverDao.hasSalaryEarnedForMonth(driverId, month);
    if (!exists) {
      await _accrueSalary(driver, month);
    }
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