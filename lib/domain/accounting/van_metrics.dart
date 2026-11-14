import 'dart:math' as math;

import 'package:transport_hisab/core/db/database.dart';

/// Per-vehicle cash and receivable figures.
///
/// These values are deliberately narrow:
/// - [tripOutstandingPaisa] only covers completed trips of this vehicle.
/// - [netCashPaisa] excludes global opening cash, driver salary/advances and
///   any other item that cannot be attributed to a vehicle.
///
/// Both figures ignore soft-deleted rows of every kind.
class VanMetrics {
  final int tripOutstandingPaisa;
  final int netCashPaisa;

  const VanMetrics({
    required this.tripOutstandingPaisa,
    required this.netCashPaisa,
  });
}

/// Computes [VanMetrics] for [vehicleId] from raw ledger rows.
///
/// - Trip outstanding (all time) =
///   max(0, SUM(completed trip fare - advance - non-deleted payments)).
/// - Net cash (all time) =
///   SUM(advances on non-deleted trips) + SUM(payments of those trips)
///   - SUM(non-deleted expenses of the vehicle)
///   - SUM(non-deleted installments of the vehicle's non-deleted loans).
VanMetrics computeVanMetrics({
  required int vehicleId,
  required List<Trip> trips,
  required List<CustomerPayment> payments,
  required List<Expense> expenses,
  required List<VehicleLoan> loans,
  required List<LoanInstallment> installments,
}) {
  final vehicleTrips = trips
      .where((t) => t.vehicleId == vehicleId && t.deletedAt == null)
      .toList();
  final tripIds = vehicleTrips.map((t) => t.id).toSet();

  final tripPayments = payments
      .where((p) => p.deletedAt == null && tripIds.contains(p.tripId))
      .toList();

  final vehicleExpenses = expenses
      .where((e) => e.vehicleId == vehicleId && e.deletedAt == null)
      .toList();

  final vehicleLoans = loans
      .where((l) => l.vehicleId == vehicleId && l.deletedAt == null)
      .toList();
  final loanIds = vehicleLoans.map((l) => l.id).toSet();

  final vehicleInstallments = installments
      .where((i) => i.deletedAt == null && loanIds.contains(i.loanId))
      .toList();

  var outstanding = 0;
  for (final trip in vehicleTrips.where((t) => t.status == 'completed')) {
    final paid = tripPayments
        .where((p) => p.tripId == trip.id)
        .fold<int>(0, (sum, p) => sum + p.amountPaisa);
    outstanding += trip.agreedFarePaisa - trip.advancePaisa - paid;
  }

  final advances =
      vehicleTrips.fold<int>(0, (sum, t) => sum + t.advancePaisa);
  final paymentsIn =
      tripPayments.fold<int>(0, (sum, p) => sum + p.amountPaisa);
  final expensesOut =
      vehicleExpenses.fold<int>(0, (sum, e) => sum + e.amountPaisa);
  final installmentsOut =
      vehicleInstallments.fold<int>(0, (sum, i) => sum + i.totalPaidPaisa);

  return VanMetrics(
    tripOutstandingPaisa: math.max(0, outstanding),
    netCashPaisa: advances + paymentsIn - expensesOut - installmentsOut,
  );
}
