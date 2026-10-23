import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/domain/accounting/accounting.dart';

/// Dashboard data model
class DashboardData {
  final int totalRevenuePaisa;
  final int totalExpensePaisa;
  final int profitPaisa;
  final int cashReceivedPaisa;
  final int cashPaidPaisa;
  final int cashBalancePaisa;
  final int totalOutstandingPaisa;
  final int loanOutstandingPaisa;
  final int driverBalancePaisa;
  final List<VanSummaryData> vanSummaries;
  final List<ExpiryAlert> expiryAlerts;

  DashboardData({
    required this.totalRevenuePaisa,
    required this.totalExpensePaisa,
    required this.profitPaisa,
    required this.cashReceivedPaisa,
    required this.cashPaidPaisa,
    required this.cashBalancePaisa,
    required this.totalOutstandingPaisa,
    required this.loanOutstandingPaisa,
    required this.driverBalancePaisa,
    required this.vanSummaries,
    required this.expiryAlerts,
  });
}

class VanSummaryData {
  final int vehicleId;
  final String regNo;
  final String type;
  final int tripCount;
  final int profitPaisa;
  final int cashBalancePaisa;
  final int outstandingPaisa;

  VanSummaryData({
    required this.vehicleId,
    required this.regNo,
    required this.type,
    required this.tripCount,
    required this.profitPaisa,
    required this.cashBalancePaisa,
    required this.outstandingPaisa,
  });
}

/// Dashboard provider
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final db = ref.watch(databaseProvider);

  // Get all active vehicles
  final vehicles = await (db.select(db.vehicles)
        ..where((t) => t.deletedAt.isNull() & t.status.equals('active')))
      .get();

  // Get current month boundaries
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Get opening cash
  final openingCashSetting = await (db.select(db.appSettings)
        ..where((t) => t.key.equals('opening_cash_paisa')))
      .getSingleOrNull();
  final openingCashPaisa = openingCashSetting != null ? int.tryParse(openingCashSetting.value) ?? 0 : 0;

  // Fetch all data for current month
  final trips = await (db.select(db.trips)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.status.equals('completed') &
            t.tripDate.isBiggerOrEqualValue(startOfMonth) &
            t.tripDate.isSmallerOrEqualValue(endOfMonth)))
      .get();

  final expenses = await (db.select(db.expenses)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.expenseDate.isBiggerOrEqualValue(startOfMonth) &
            t.expenseDate.isSmallerOrEqualValue(endOfMonth)))
      .get();

  final customerPayments = await (db.select(db.customerPayments)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.paymentDate.isBiggerOrEqualValue(startOfMonth) &
            t.paymentDate.isSmallerOrEqualValue(endOfMonth)))
      .get();

  final driverTransactions = await (db.select(db.driverTransactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.transactionDate.isBiggerOrEqualValue(startOfMonth) &
            t.transactionDate.isSmallerOrEqualValue(endOfMonth)))
      .get();

  final loanInstallments = await (db.select(db.loanInstallments)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.installmentDate.isBiggerOrEqualValue(startOfMonth) &
            t.installmentDate.isSmallerOrEqualValue(endOfMonth)))
      .get();

  // Compute totals using accounting engine
  final totalRevenuePaisa = trips.fold(0, (sum, t) => sum + t.agreedFarePaisa);
  final totalExpensePaisa = expenses.fold(0, (sum, e) => sum + e.amountPaisa);
  final profitPaisa = totalRevenuePaisa - totalExpensePaisa;

  // Cash received = customer payments in month
  final cashReceivedPaisa = customerPayments.fold(0, (sum, p) => sum + p.amountPaisa);

  // Cash paid = expenses + driver payments + loan installments
  final expensesPaidPaisa = expenses.fold<int>(0, (sum, e) => sum + e.amountPaisa);
  final driverPaidPaisa = driverTransactions
      .where((t) => t.type == 'salary_paid' || t.type == 'advance_given' || t.type == 'loan_given')
      .fold<int>(0, (sum, t) => sum + t.amountPaisa);
  final loanPaidPaisa = loanInstallments.fold<int>(0, (sum, i) => sum + i.totalPaidPaisa);
  final cashPaidPaisa = expensesPaidPaisa + driverPaidPaisa + loanPaidPaisa;

  // Cash balance
  final cashBalancePaisa = openingCashPaisa + cashReceivedPaisa - cashPaidPaisa;

  // Fetch all-time data for cumulative balances
  final allTrips = await (db.select(db.trips)..where((t) => t.deletedAt.isNull())).get();
  final allPayments = await (db.select(db.customerPayments)..where((t) => t.deletedAt.isNull())).get();
  final allCustomers = await (db.select(db.customers)..where((t) => t.deletedAt.isNull())).get();
  final allLoans = await (db.select(db.vehicleLoans)..where((t) => t.deletedAt.isNull())).get();
  final allInstallments = await (db.select(db.loanInstallments)..where((t) => t.deletedAt.isNull())).get();
  final allDriverTxs = await (db.select(db.driverTransactions)..where((t) => t.deletedAt.isNull())).get();

  // Total customer outstanding
  final totalFareAllTime = allTrips.fold<int>(0, (sum, t) => sum + t.agreedFarePaisa);
  final totalPaidAllTime = allPayments.fold<int>(0, (sum, p) => sum + p.amountPaisa);
  final totalOpeningCustomers = allCustomers.fold<int>(0, (sum, c) => sum + c.openingBalancePaisa);
  final totalOutstandingPaisa = (totalOpeningCustomers + totalFareAllTime - totalPaidAllTime).clamp(0, 1000000000000);

  // Loan outstanding
  final totalPrincipal = allLoans.fold<int>(0, (sum, l) => sum + l.principalPaisa);
  final totalPrincipalPaid = allInstallments.fold<int>(0, (sum, i) => sum + i.principalPortionPaisa);
  final loanOutstandingPaisa = (totalPrincipal - totalPrincipalPaid).clamp(0, 1000000000000);

  // Driver balance
  final totalSalaryEarned = allDriverTxs.where((t) => t.type == 'salary_earned').fold<int>(0, (sum, t) => sum + t.amountPaisa);
  final totalSalaryPaid = allDriverTxs.where((t) => t.type == 'salary_paid').fold<int>(0, (sum, t) => sum + t.amountPaisa);
  final totalAdvancesGiven = allDriverTxs.where((t) => t.type == 'advance_given').fold<int>(0, (sum, t) => sum + t.amountPaisa);
  final totalAdvancesDeducted = allDriverTxs.where((t) => t.type == 'advance_deducted').fold<int>(0, (sum, t) => sum + t.amountPaisa);
  final driverBalancePaisa = totalSalaryEarned - totalSalaryPaid - (totalAdvancesGiven - totalAdvancesDeducted);

  // Van summaries
  final vanSummaries = <VanSummaryData>[];
  for (final vehicle in vehicles) {
    final vehicleTrips = trips.where((t) => t.vehicleId == vehicle.id).toList();
    final vehicleExpensesList = expenses.where((e) => e.vehicleId == vehicle.id).toList();
    final vehicleRevenue = vehicleTrips.fold<int>(0, (sum, t) => sum + t.agreedFarePaisa);
    final vehicleExpenseTotal = vehicleExpensesList.fold<int>(0, (sum, e) => sum + e.amountPaisa);
    final vehicleProfit = vehicleRevenue - vehicleExpenseTotal;

    vanSummaries.add(VanSummaryData(
      vehicleId: vehicle.id,
      regNo: vehicle.regNo,
      type: vehicle.type,
      tripCount: vehicleTrips.length,
      profitPaisa: vehicleProfit,
      cashBalancePaisa: 0,
      outstandingPaisa: 0,
    ));
  }

  // Expiry alerts
  final expiryAlerts = <ExpiryAlert>[];
  final alertNow = DateTime.now();
  for (final vehicle in vehicles) {
    if (vehicle.insuranceExpiry != null) {
      final days = vehicle.insuranceExpiry!.difference(alertNow).inDays;
      if (days <= 30) {
        expiryAlerts.add(ExpiryAlert(
          vehicleId: vehicle.id,
          vehicleRegNo: vehicle.regNo,
          type: 'insurance',
          expiryDate: vehicle.insuranceExpiry!,
          daysLeft: days,
        ));
      }
    }
    if (vehicle.fitnessExpiry != null) {
      final days = vehicle.fitnessExpiry!.difference(alertNow).inDays;
      if (days <= 30) {
        expiryAlerts.add(ExpiryAlert(
          vehicleId: vehicle.id,
          vehicleRegNo: vehicle.regNo,
          type: 'fitness',
          expiryDate: vehicle.fitnessExpiry!,
          daysLeft: days,
        ));
      }
    }
    if (vehicle.taxExpiry != null) {
      final days = vehicle.taxExpiry!.difference(alertNow).inDays;
      if (days <= 30) {
        expiryAlerts.add(ExpiryAlert(
          vehicleId: vehicle.id,
          vehicleRegNo: vehicle.regNo,
          type: 'tax',
          expiryDate: vehicle.taxExpiry!,
          daysLeft: days,
        ));
      }
    }
  }

  return DashboardData(
    totalRevenuePaisa: totalRevenuePaisa,
    totalExpensePaisa: totalExpensePaisa,
    profitPaisa: profitPaisa,
    cashReceivedPaisa: cashReceivedPaisa,
    cashPaidPaisa: cashPaidPaisa,
    cashBalancePaisa: cashBalancePaisa,
    totalOutstandingPaisa: totalOutstandingPaisa,
    loanOutstandingPaisa: loanOutstandingPaisa,
    driverBalancePaisa: driverBalancePaisa,
    vanSummaries: vanSummaries,
    expiryAlerts: expiryAlerts,
  );
});