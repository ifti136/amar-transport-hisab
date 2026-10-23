import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/driver_loan_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';

/// Driver Transaction DAO provider
final driverTransactionDaoProvider = Provider<DriverTransactionDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return DriverTransactionDao(db, audit);
});

/// Vehicle Loan DAO provider
final vehicleLoanDaoProvider = Provider<VehicleLoanDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return VehicleLoanDao(db, audit);
});

/// Loan Installment DAO provider
final loanInstallmentDaoProvider = Provider<LoanInstallmentDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return LoanInstallmentDao(db, audit);
});

/// Stream of driver transactions
final driverTransactionsProvider = StreamProvider.family<List<DriverTransaction>, int>((ref, driverId) {
  final dao = ref.watch(driverTransactionDaoProvider);
  return dao.watchTransactionsForDriver(driverId);
});

/// Provider for driver ledger
final driverLedgerProvider = FutureProvider.family<List<DriverLedgerEntry>, DriverLedgerFilter>((ref, filter) async {
  final dao = ref.watch(driverTransactionDaoProvider);
  final txs = await dao.getTransactionsForDriverInRange(filter.driverId, filter.from, filter.to);
  int running = 0;
  final entries = <DriverLedgerEntry>[];
  for (final t in txs) {
    int amount = t.amountPaisa;
    String desc;
    switch (t.type) {
      case 'salary_earned': desc = 'Salary Earned'; break;
      case 'salary_paid': desc = 'Salary Paid'; amount = -amount; break;
      case 'advance_given': desc = 'Advance Given'; amount = -amount; break;
      case 'advance_deducted': desc = 'Advance Deducted'; break;
      case 'loan_given': desc = 'Loan Given'; amount = -amount; break;
      case 'loan_repaid': desc = 'Loan Repaid'; break;
      default: desc = t.type;
    }
    running += amount;
    entries.add(DriverLedgerEntry(
      date: t.transactionDate,
      type: t.type,
      description: desc,
      amount: amount,
      balance: running,
    ));
  }
  return entries;
});

class DriverLedgerFilter {
  final int driverId;
  final DateTime from;
  final DateTime to;

  const DriverLedgerFilter({
    required this.driverId,
    required this.from,
    required this.to,
  });
}

class DriverLedgerEntry {
  final DateTime date;
  final String type;
  final String description;
  final int amount; // Positive = increases balance, Negative = decreases
  int balance;

  DriverLedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.balance,
  });
}

/// Provider for driver balance
final driverBalanceProvider = FutureProvider.family<int, DriverBalanceFilter>((ref, filter) async {
  final dao = ref.watch(driverTransactionDaoProvider);
  return dao.getDriverBalance(filter.driverId, filter.upTo);
});

class DriverBalanceFilter {
  final int driverId;
  final DateTime upTo;

  const DriverBalanceFilter({
    required this.driverId,
    required this.upTo,
  });
}

/// Provider for outstanding advance
final outstandingAdvanceProvider = FutureProvider.family<int, OutstandingAdvanceFilter>((ref, filter) async {
  final dao = ref.watch(driverTransactionDaoProvider);
  return dao.getOutstandingAdvance(filter.driverId, filter.upTo);
});

class OutstandingAdvanceFilter {
  final int driverId;
  final DateTime upTo;

  const OutstandingAdvanceFilter({
    required this.driverId,
    required this.upTo,
  });
}

/// Provider for loan schedule
final loanScheduleProvider = FutureProvider.family<List<LoanScheduleEntry>, int>((ref, vehicleId) async {
  final dao = ref.watch(loanInstallmentDaoProvider);
  return dao.getLoanScheduleForVehicle(vehicleId);
});

/// Provider for loan outstanding
final loanOutstandingProvider = FutureProvider.family<int, LoanOutstandingFilter>((ref, filter) async {
  final dao = ref.watch(vehicleLoanDaoProvider);
  return dao.getLoanOutstanding(filter.loanId, filter.upTo);
});

class LoanOutstandingFilter {
  final int loanId;
  final DateTime upTo;

  const LoanOutstandingFilter({
    required this.loanId,
    required this.upTo,
  });
}