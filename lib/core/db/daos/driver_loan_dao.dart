import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/driver_transactions.dart';
import '../tables/vehicle_loans.dart';
import '../tables/loan_installments.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class DriverTransactionDao extends BaseDao<DriverTransactions, DriverTransactionsCompanion> {
  DriverTransactionDao(super.db, super.audit) : super(tableName: 'driver_transactions');

  @override
  TableInfo get table => db.driverTransactions;

  @override
  Map<String, dynamic> _companionToMap(DriverTransactionsCompanion companion) {
    return {
      'driver_id': companion.driverId.valueOrNull,
      'type': companion.type.valueOrNull,
      'amount_paisa': companion.amountPaisa.valueOrNull,
      'transaction_date': companion.transactionDate.valueOrNull?.toIso8601String(),
      'note': companion.note.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row.id,
      'driver_id': row.driverId,
      'type': row.type,
      'amount_paisa': row.amountPaisa,
      'transaction_date': row.transactionDate.toIso8601String(),
      'note': row.note,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get transactions for a driver
  Stream<List<DriverTransaction>> watchTransactionsForDriver(int driverId) {
    return (db.select(db.driverTransactions)
          ..where((t) => t.driverId.equals(driverId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate), (t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Future<List<DriverTransaction>> getTransactionsForDriver(int driverId) async {
    return (db.select(db.driverTransactions)
          ..where((t) => t.driverId.equals(driverId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate), (t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  // Get transactions for a driver in a date range
  Future<List<DriverTransaction>> getTransactionsForDriverInRange(int driverId, DateTime from, DateTime to) async {
    return (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.transactionDate.isBiggerOrEqualValue(from) &
              t.transactionDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  // Check if salary_earned exists for a driver in a month
  Future<bool> hasSalaryEarnedForMonth(int driverId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('salary_earned') &
              t.transactionDate.isBiggerOrEqualValue(startOfMonth) &
              t.transactionDate.isSmallerOrEqualValue(endOfMonth)))
        .get();

    return result.isNotEmpty;
  }

  // Get total salary earned for a driver up to a date
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

  // Get total salary paid for a driver up to a date
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

  // Get total advances given for a driver up to a date
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

  // Get total advances deducted for a driver up to a date
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

  // Get total loans given for a driver up to a date
  Future<int> getTotalLoansGiven(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('loan_given') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();
    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  // Get total loans repaid for a driver up to a date
  Future<int> getTotalLoansRepaid(int driverId, DateTime upTo) async {
    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('loan_repaid') &
              t.transactionDate.isSmallerOrEqualValue(upTo)))
        .get();
    return result.fold<int>(0, (sum, t) => sum + t.amountPaisa);
  }

  // Get driver balance up to a date
  Future<int> getDriverBalance(int driverId, DateTime upTo) async {
    final salaryEarned = await getTotalSalaryEarned(driverId, upTo);
    final salaryPaid = await getTotalSalaryPaid(driverId, upTo);
    final advancesGiven = await getTotalAdvancesGiven(driverId, upTo);
    final advancesDeducted = await getTotalAdvancesDeducted(driverId, upTo);
    final loansGiven = await getTotalLoansGiven(driverId, upTo);
    final loansRepaid = await getTotalLoansRepaid(driverId, upTo);

    return salaryEarned - salaryPaid - advancesGiven + advancesDeducted + loansGiven - loansRepaid;
  }

  // Get outstanding advance for a driver
  Future<int> getOutstandingAdvance(int driverId, DateTime upTo) async {
    final advancesGiven = await getTotalAdvancesGiven(driverId, upTo);
    final advancesDeducted = await getTotalAdvancesDeducted(driverId, upTo);
    return advancesGiven - advancesDeducted;
  }
}

class VehicleLoanDao extends BaseDao<VehicleLoans, VehicleLoansCompanion> {
  VehicleLoanDao(super.db, super.audit) : super(tableName: 'vehicle_loans');

  @override
  TableInfo get table => db.vehicleLoans;

  @override
  Map<String, dynamic> _companionToMap(VehicleLoansCompanion companion) {
    return {
      'vehicle_id': companion.vehicleId.valueOrNull,
      'principal_paisa': companion.principalPaisa.valueOrNull,
      'annual_interest_rate_bps': companion.annualInterestRateBps.valueOrNull,
      'start_date': companion.startDate.valueOrNull?.toIso8601String(),
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row.id,
      'vehicle_id': row.vehicleId,
      'principal_paisa': row.principalPaisa,
      'annual_interest_rate_bps': row.annualInterestRateBps,
      'start_date': row.startDate.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get loans for a vehicle
  Stream<List<VehicleLoan>> watchLoansForVehicle(int vehicleId) {
    return (db.select(db.vehicleLoans)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  Future<List<VehicleLoan>> getLoansForVehicle(int vehicleId) async {
    return (db.select(db.vehicleLoans)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  // Get all active loans
  Stream<List<VehicleLoan>> watchActiveLoans() {
    return (db.select(db.vehicleLoans)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  Future<List<VehicleLoan>> getActiveLoans() async {
    return (db.select(db.vehicleLoans)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  // Get loan outstanding principal
  Future<int> getLoanOutstanding(int loanId, DateTime upTo) async {
    final loan = await getById(loanId);
    if (loan == null) return 0;

    final installments = await (db.select(db.loanInstallments)
          ..where((t) =>
              t.loanId.equals(loanId) &
              t.deletedAt.isNull() &
              t.installmentDate.isSmallerOrEqualValue(upTo)))
        .get();

    final totalPrincipalPaid = installments.fold(0, (sum, i) => sum + i.principalPortionPaisa);
    return loan.principalPaisa - totalPrincipalPaid;
  }
}

class LoanInstallmentDao extends BaseDao<LoanInstallments, LoanInstallmentsCompanion> {
  LoanInstallmentDao(super.db, super.audit) : super(tableName: 'loan_installments');

  @override
  TableInfo get table => db.loanInstallments;

  @override
  Map<String, dynamic> _companionToMap(LoanInstallmentsCompanion companion) {
    return {
      'loan_id': companion.loanId.valueOrNull,
      'installment_date': companion.installmentDate.valueOrNull?.toIso8601String(),
      'total_paid_paisa': companion.totalPaidPaisa.valueOrNull,
      'principal_portion_paisa': companion.principalPortionPaisa.valueOrNull,
      'interest_portion_paisa': companion.interestPortionPaisa.valueOrNull,
      'note': companion.note.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row.id,
      'loan_id': row.loanId,
      'installment_date': row.installmentDate.toIso8601String(),
      'total_paid_paisa': row.totalPaidPaisa,
      'principal_portion_paisa': row.principalPortionPaisa,
      'interest_portion_paisa': row.interestPortionPaisa,
      'note': row.note,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get installments for a loan
  Stream<List<LoanInstallment>> watchInstallmentsForLoan(int loanId) {
    return (db.select(db.loanInstallments)
          ..where((t) => t.loanId.equals(loanId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.installmentDate)]))
        .watch();
  }

  Future<List<LoanInstallment>> getInstallmentsForLoan(int loanId) async {
    return (db.select(db.loanInstallments)
          ..where((t) => t.loanId.equals(loanId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.installmentDate)]))
        .get();
  }

  // Get total interest paid for a loan up to a date
  Future<int> getTotalInterestPaid(int loanId, DateTime upTo) async {
    final installments = await (db.select(db.loanInstallments)
          ..where((t) =>
              t.loanId.equals(loanId) &
              t.deletedAt.isNull() &
              t.installmentDate.isSmallerOrEqualValue(upTo)))
        .get();
    return installments.fold<int>(0, (sum, i) => sum + i.interestPortionPaisa);
  }

  // Get total principal paid for a loan up to a date
  Future<int> getTotalPrincipalPaid(int loanId, DateTime upTo) async {
    final installments = await (db.select(db.loanInstallments)
          ..where((t) =>
              t.loanId.equals(loanId) &
              t.deletedAt.isNull() &
              t.installmentDate.isSmallerOrEqualValue(upTo)))
        .get();
    return installments.fold<int>(0, (sum, i) => sum + i.principalPortionPaisa);
  }

  // Get loan schedule for a vehicle
  Future<List<LoanScheduleEntry>> getLoanScheduleForVehicle(int vehicleId) async {
    final loans = await (db.select(db.vehicleLoans)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull()))
        .get();
    final entries = <LoanScheduleEntry>[];

    for (final loan in loans) {
      final installments = await getInstallmentsForLoan(loan.id);
      int outstanding = loan.principalPaisa;

      for (final inst in installments) {
        outstanding -= inst.principalPortionPaisa;
        entries.add(LoanScheduleEntry(
          loanId: loan.id,
          date: inst.installmentDate,
          totalPaid: inst.totalPaidPaisa,
          principal: inst.principalPortionPaisa,
          interest: inst.interestPortionPaisa,
          outstanding: outstanding,
        ));
      }

      // Add current outstanding if no installments yet
      if (installments.isEmpty) {
        entries.add(LoanScheduleEntry(
          loanId: loan.id,
          date: loan.startDate,
          totalPaid: 0,
          principal: 0,
          interest: 0,
          outstanding: loan.principalPaisa,
        ));
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }
}

class LoanScheduleEntry {
  final int loanId;
  final DateTime date;
  final int totalPaid;
  final int principal;
  final int interest;
  final int outstanding;

  LoanScheduleEntry({
    required this.loanId,
    required this.date,
    required this.totalPaid,
    required this.principal,
    required this.interest,
    required this.outstanding,
  });
}