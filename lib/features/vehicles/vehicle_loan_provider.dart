import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/driver_loan_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';

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

/// Stream of loans for a vehicle
final vehicleLoansProvider = StreamProvider.family<List<VehicleLoan>, int>((ref, vehicleId) {
  final dao = ref.watch(vehicleLoanDaoProvider);
  return dao.watchLoansForVehicle(vehicleId);
});

/// Stream of all active loans
final allLoansProvider = StreamProvider<List<VehicleLoan>>((ref) {
  final dao = ref.watch(vehicleLoanDaoProvider);
  return dao.watchActiveLoans();
});

/// Provider for loan installments
final loanInstallmentsProvider = StreamProvider.family<List<LoanInstallment>, int>((ref, loanId) {
  final dao = ref.watch(loanInstallmentDaoProvider);
  return dao.watchInstallmentsForLoan(loanId);
});

class LoanOutstandingFilter {
  final int loanId;
  final DateTime upTo;
  const LoanOutstandingFilter({required this.loanId, required this.upTo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanOutstandingFilter &&
          other.loanId == loanId &&
          other.upTo == upTo;

  @override
  int get hashCode => Object.hash(loanId, upTo);
}

final loanOutstandingProvider = FutureProvider.family<int, LoanOutstandingFilter>((ref, filter) async {
  final dao = ref.watch(vehicleLoanDaoProvider);
  return dao.getLoanOutstanding(filter.loanId, filter.upTo);
});
