import 'package:transport_hisab/domain/accounting/models.dart';
import 'package:transport_hisab/core/db/database.dart';

/// Compute van monthly P&L
VanMonthlyPnL computeVanMonthlyPnL({
  required int vehicleId,
  required int year,
  required int month,
  required List<Trip> trips,
  required List<Expense> expenses,
  required List<LoanInstallment> loanInstallments,
}) {
  // Filter trips for this vehicle and month (completed only)
  final vehicleTrips = trips.where((t) =>
      t.vehicleId == vehicleId &&
      t.deletedAt == null &&
      t.status == 'completed' &&
      t.tripDate.year == year &&
      t.tripDate.month == month).toList();

  // Revenue = sum of agreed fares for completed trips
  final revenuePaisa = vehicleTrips.fold(0, (sum, t) => sum + t.agreedFarePaisa);

  // Filter expenses for this vehicle and month
  final vehicleExpenses = expenses.where((e) =>
      e.vehicleId == vehicleId &&
      e.deletedAt == null &&
      e.expenseDate.year == year &&
      e.expenseDate.month == month).toList();

  // Group expenses by category
  final expensesByCategoryPaisa = <String, int>{};
  for (final e in vehicleExpenses) {
    expensesByCategoryPaisa[e.category] = (expensesByCategoryPaisa[e.category] ?? 0) + e.amountPaisa;
  }

  final totalExpensesPaisa = vehicleExpenses.fold(0, (sum, e) => sum + e.amountPaisa);

  // Loan interest for this vehicle and month
  final loanInterestPaisa = loanInstallments
      .where((i) =>
          i.deletedAt == null &&
          i.installmentDate.year == year &&
          i.installmentDate.month == month)
      .fold(0, (sum, i) => sum + i.interestPortionPaisa);

  // Depreciation (always 0 per PRD)
  const depreciationPaisa = 0;

  // Profit = Revenue - Expenses - Loan Interest - Depreciation
  final profitPaisa = revenuePaisa - totalExpensesPaisa - loanInterestPaisa;

  return VanMonthlyPnL(
    vehicleId: vehicleId,
    year: year,
    month: month,
    revenuePaisa: revenuePaisa,
    expensesByCategoryPaisa: expensesByCategoryPaisa,
    totalExpensesPaisa: totalExpensesPaisa,
    loanInterestPaisa: loanInterestPaisa,
    depreciationPaisa: 0,
    profitPaisa: profitPaisa,
  );
}

/// Compute cash flow for a month
CashFlow computeCashFlow({
  required int year,
  required int month,
  required int openingCashPaisa,
  required List<CustomerPayment> customerPayments,
  required List<Expense> expenses,
  required List<DriverTransaction> driverTransactions,
  required List<LoanInstallment> loanInstallments,
}) {
  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

  // Cash received = customer payments in month
  final paymentsInMonth = customerPayments.where((p) =>
      p.deletedAt == null &&
      p.paymentDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
      p.paymentDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

  final cashReceivedPaisa = paymentsInMonth.fold(0, (sum, p) => sum + p.amountPaisa);

  // Receipts by type
  final receiptsByTypePaisa = <String, int>{'customer_payments': cashReceivedPaisa};

  // Cash paid = expenses + driver payments + loan installments
  final expensesInMonth = expenses.where((e) =>
      e.deletedAt == null &&
      e.expenseDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
      e.expenseDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

  final expensesPaidPaisa = expensesInMonth.fold(0, (sum, e) => sum + e.amountPaisa);

  final driverPaymentsInMonth = driverTransactions.where((t) =>
      t.deletedAt == null &&
      (t.type == 'salary_paid' || t.type == 'advance_given' || t.type == 'loan_given') &&
      t.transactionDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
      t.transactionDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

  final driverPaidPaisa = driverPaymentsInMonth.fold(0, (sum, t) => sum + t.amountPaisa);

  final loanInstallmentsInMonth = loanInstallments.where((i) =>
      i.deletedAt == null &&
      i.installmentDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
      i.installmentDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

  final loanPaidPaisa = loanInstallmentsInMonth.fold(0, (sum, i) => sum + i.totalPaidPaisa);

  final cashPaidPaisa = expensesPaidPaisa + driverPaidPaisa + loanPaidPaisa;

  // Payments by type
  final paymentsByTypePaisa = <String, int>{
    'expenses': expensesPaidPaisa,
    'driver_payments': driverPaidPaisa,
    'loan_installments': loanPaidPaisa,
  };

  final closingCashPaisa = openingCashPaisa + cashReceivedPaisa - cashPaidPaisa;

  return CashFlow(
    year: year,
    month: month,
    openingCashPaisa: openingCashPaisa,
    cashReceivedPaisa: cashReceivedPaisa,
    cashPaidPaisa: cashPaidPaisa,
    closingCashPaisa: closingCashPaisa,
    receiptsByTypePaisa: receiptsByTypePaisa,
    paymentsByTypePaisa: paymentsByTypePaisa,
  );
}

/// Compute customer ledger
CustomerLedger computeCustomerLedger({
  required int customerId,
  required DateTime from,
  required DateTime to,
  required Customer customer,
  required List<Trip> trips,
  required List<CustomerPayment> payments,
}) {
  final entries = <CustomerLedgerEntry>[];

  // Opening balance
  int runningBalance = customer.openingBalancePaisa;
  if (customer.openingBalancePaisa != 0) {
    entries.add(CustomerLedgerEntry(
      date: from,
      type: 'opening_balance',
      description: 'Opening Balance',
      amountPaisa: customer.openingBalancePaisa,
      balancePaisa: runningBalance,
    ));
  }

  // Trips (revenue increases outstanding)
  final customerTrips = trips.where((t) =>
      t.customerId == customerId &&
      t.deletedAt == null &&
      t.status == 'completed' &&
      t.tripDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      t.tripDate.isBefore(to.add(const Duration(seconds: 1)))).toList();

  for (final trip in customerTrips) {
    runningBalance += trip.agreedFarePaisa;
    entries.add(CustomerLedgerEntry(
      date: trip.tripDate,
      type: 'trip',
      description: 'Trip #${trip.id}',
      amountPaisa: trip.agreedFarePaisa,
      balancePaisa: runningBalance,
    ));
  }

  // Payments (decrease outstanding)
  final customerPayments = payments.where((p) =>
      p.customerId == customerId &&
      p.deletedAt == null &&
      p.paymentDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      p.paymentDate.isBefore(to.add(const Duration(seconds: 1)))).toList();

  for (final payment in customerPayments) {
    runningBalance -= payment.amountPaisa;
    entries.add(CustomerLedgerEntry(
      date: payment.paymentDate,
      type: 'payment',
      description: 'Payment received',
      amountPaisa: -payment.amountPaisa,
      balancePaisa: runningBalance,
    ));
  }

  // Sort by date
  entries.sort((a, b) => a.date.compareTo(b.date));

  // Recompute running balance after sorting
  runningBalance = 0;
  final finalEntries = <CustomerLedgerEntry>[];
  for (final entry in entries) {
    runningBalance += entry.amountPaisa;
    finalEntries.add(CustomerLedgerEntry(
      date: entry.date,
      type: entry.type,
      description: entry.description,
      amountPaisa: entry.amountPaisa,
      balancePaisa: runningBalance,
    ));
  }

  return CustomerLedger(
    customerId: customerId,
    from: from,
    to: to,
    openingBalancePaisa: customer.openingBalancePaisa,
    entries: finalEntries,
    closingBalancePaisa: runningBalance,
  );
}

/// Compute driver ledger
DriverLedger computeDriverLedger({
  required int driverId,
  required DateTime from,
  required DateTime to,
  required List<DriverTransaction> transactions,
}) {
  final filtered = transactions.where((t) =>
      t.driverId == driverId &&
      t.deletedAt == null &&
      t.transactionDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      t.transactionDate.isBefore(to.add(const Duration(seconds: 1)))).toList();

  filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

  final entries = <DriverLedgerEntry>[];
  int runningBalance = 0;

  for (final t in filtered) {
    int amount = t.amountPaisa;
    String description;
    switch (t.type) {
      case 'salary_earned':
        description = 'Salary Earned';
        break;
      case 'salary_paid':
        description = 'Salary Paid';
        amount = -amount;
        break;
      case 'advance_given':
        description = 'Advance Given';
        amount = -amount;
        break;
      case 'advance_deducted':
        description = 'Advance Deducted';
        break;
      case 'loan_given':
        description = 'Loan Given';
        amount = -amount;
        break;
      case 'loan_repaid':
        description = 'Loan Repaid';
        break;
      default:
        description = t.type;
    }

    runningBalance += amount;
    entries.add(DriverLedgerEntry(
      date: t.transactionDate,
      type: t.type,
      description: description,
      amountPaisa: amount,
      balancePaisa: runningBalance,
    ));
  }

  return DriverLedger(
    driverId: driverId,
    from: from,
    to: to,
    entries: entries,
    closingBalancePaisa: runningBalance,
  );
}

/// Compute trip register
TripRegister computeTripRegister({
  required DateTime from,
  required DateTime to,
  int? vehicleId,
  required List<Trip> trips,
  required List<CustomerPayment> payments,
  required List<Customer> customers,
  required List<Vehicle> vehicles,
}) {
  final filtered = trips.where((t) =>
      t.deletedAt == null &&
      t.status == 'completed' &&
      t.tripDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      t.tripDate.isBefore(to.add(const Duration(seconds: 1))) &&
      (vehicleId == null || t.vehicleId == vehicleId)).toList();

  filtered.sort((a, b) => a.tripDate.compareTo(b.tripDate));

  final entries = <TripRegisterEntry>[];
  int totalFare = 0;
  int totalAdvance = 0;
  int totalOutstanding = 0;

  for (final trip in filtered) {
    final customer = customers.firstWhere((c) => c.id == trip.customerId, orElse: () => Customer(id: 0, name: 'Unknown', phone: null, openingBalancePaisa: 0, createdAt: DateTime.now(), updatedAt: DateTime.now(), deletedAt: null));
    final vehicle = vehicles.firstWhere((v) => v.id == trip.vehicleId, orElse: () => Vehicle(id: 0, regNo: 'Unknown', type: '', insuranceExpiry: null, fitnessExpiry: null, taxExpiry: null, status: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), deletedAt: null));

    final tripPayments = payments.where((p) => p.tripId == trip.id && p.deletedAt == null).toList();
    final totalPaid = tripPayments.fold(0, (sum, p) => sum + p.amountPaisa);
    final outstanding = trip.agreedFarePaisa - trip.advancePaisa - totalPaid;

    totalFare += trip.agreedFarePaisa;
    totalAdvance += trip.advancePaisa;
    totalOutstanding += outstanding;

    entries.add(TripRegisterEntry(
      tripId: trip.id,
      date: trip.tripDate,
      customerName: customer.name,
      vehicleRegNo: vehicle.regNo,
      farePaisa: trip.agreedFarePaisa,
      advancePaisa: trip.advancePaisa,
      outstandingPaisa: outstanding,
    ));
  }

  return TripRegister(
    from: from,
    to: to,
    vehicleId: vehicleId,
    entries: entries,
    totalFarePaisa: totalFare,
    totalAdvancePaisa: totalAdvance,
    totalOutstandingPaisa: totalOutstanding,
  );
}

/// Compute expense register
ExpenseRegister computeExpenseRegister({
  required DateTime from,
  required DateTime to,
  int? vehicleId,
  String? category,
  required List<Expense> expenses,
  required List<Vehicle> vehicles,
}) {
  final filtered = expenses.where((e) =>
      e.deletedAt == null &&
      e.expenseDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      e.expenseDate.isBefore(to.add(const Duration(seconds: 1))) &&
      (vehicleId == null || e.vehicleId == vehicleId) &&
      (category == null || e.category == category)).toList();

  filtered.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

  final entries = <ExpenseRegisterEntry>[];
  final totalsByCategory = <String, int>{};
  int grandTotal = 0;

  for (final e in filtered) {
    final vehicle = vehicles.firstWhere((v) => v.id == e.vehicleId, orElse: () => Vehicle(id: 0, regNo: 'Unknown', type: '', insuranceExpiry: null, fitnessExpiry: null, taxExpiry: null, status: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), deletedAt: null));

    totalsByCategory[e.category] = (totalsByCategory[e.category] ?? 0) + e.amountPaisa;
    grandTotal += e.amountPaisa;

    entries.add(ExpenseRegisterEntry(
      expenseId: e.id,
      date: e.expenseDate,
      category: e.category,
      vehicleRegNo: vehicle.regNo,
      tripId: e.tripId,
      amountPaisa: e.amountPaisa,
    ));
  }

  return ExpenseRegister(
    from: from,
    to: to,
    vehicleId: vehicleId,
    category: category,
    entries: entries,
    totalsByCategoryPaisa: totalsByCategory,
    grandTotalPaisa: grandTotal,
  );
}

/// Compute fuel register
FuelRegister computeFuelRegister({
  required DateTime from,
  required DateTime to,
  int? vehicleId,
  required List<FuelRecord> fuelRecords,
  required List<Vehicle> vehicles,
}) {
  final filtered = fuelRecords.where((f) =>
      f.deletedAt == null &&
      f.fuelDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
      f.fuelDate.isBefore(to.add(const Duration(seconds: 1))) &&
      (vehicleId == null || f.vehicleId == vehicleId)).toList();

  filtered.sort((a, b) => a.fuelDate.compareTo(b.fuelDate));

  final entries = <FuelRegisterEntry>[];
  double totalLitres = 0;
  int totalCost = 0;

  for (int i = 0; i < filtered.length; i++) {
    final f = filtered[i];
    final vehicle = vehicles.firstWhere((v) => v.id == f.vehicleId, orElse: () => Vehicle(id: 0, regNo: 'Unknown', type: '', insuranceExpiry: null, fitnessExpiry: null, taxExpiry: null, status: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), deletedAt: null));

    final totalPaisa = (f.ratePerLitrePaisa * f.litres).round();
    totalLitres += f.litres;
    totalCost += totalPaisa;

    double? kmPerLitre;
    if (i > 0) {
      final prev = filtered[i - 1];
      if (prev.vehicleId == f.vehicleId) {
        final km = f.odometer - prev.odometer;
        if (km > 0 && f.litres > 0) {
          kmPerLitre = km / f.litres;
        }
      }
    }

    entries.add(FuelRegisterEntry(
      fuelId: f.id,
      date: f.fuelDate,
      vehicleRegNo: vehicles.firstWhere((v) => v.id == f.vehicleId, orElse: () => Vehicle(id: 0, regNo: 'Unknown', type: '', insuranceExpiry: null, fitnessExpiry: null, taxExpiry: null, status: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), deletedAt: null)).regNo,
      litres: f.litres,
      ratePerLitrePaisa: f.ratePerLitrePaisa,
      totalPaisa: totalPaisa,
      odometer: f.odometer,
      kmPerLitre: kmPerLitre,
    ));
  }

  final avgKmPerLitre = filtered.isNotEmpty
      ? filtered.fold(0.0, (sum, f) => sum + f.litres) > 0
          ? filtered.where((f) => f.odometer > 0).fold(0, (sum, f) => sum + f.odometer) / filtered.fold(0.0, (sum, f) => sum + f.litres)
          : 0.0
      : 0.0;

  return FuelRegister(
    from: from,
    to: to,
    vehicleId: vehicleId,
    entries: entries,
    totalLitres: totalLitres,
    totalCostPaisa: totalCost,
    avgKmPerLitre: avgKmPerLitre,
  );
}

/// Compute loan schedule
LoanSchedule computeLoanSchedule({
  required int vehicleId,
  required List<VehicleLoan> loans,
  required List<LoanInstallment> installments,
}) {
  final vehicleLoans = loans.where((l) => l.vehicleId == vehicleId && l.deletedAt == null).toList();
  final entries = <LoanScheduleEntry>[];

  for (final loan in vehicleLoans) {
    final loanInstallments = installments.where((i) => i.loanId == loan.id && i.deletedAt == null).toList();
    loanInstallments.sort((a, b) => a.installmentDate.compareTo(b.installmentDate));

    int outstanding = loan.principalPaisa;

    for (final inst in loanInstallments) {
      outstanding -= inst.principalPortionPaisa;
      entries.add(LoanScheduleEntry(
        loanId: loan.id,
        date: inst.installmentDate,
        totalPaidPaisa: inst.totalPaidPaisa,
        principalPaisa: inst.principalPortionPaisa,
        interestPaisa: inst.interestPortionPaisa,
        outstandingPaisa: outstanding,
      ));
    }

    // Add current outstanding if no installments yet
    if (loanInstallments.isEmpty) {
      entries.add(LoanScheduleEntry(
        loanId: loan.id,
        date: loan.startDate,
        totalPaidPaisa: 0,
        principalPaisa: 0,
        interestPaisa: 0,
        outstandingPaisa: loan.principalPaisa,
      ));
    }
  }

  entries.sort((a, b) => a.date.compareTo(b.date));

  return LoanSchedule(vehicleId: vehicleId, entries: entries);
}

/// Compute expiry alerts
ExpiryAlerts computeExpiryAlerts({
  required List<Vehicle> vehicles,
}) {
  final now = DateTime.now();
  final alerts = <ExpiryAlert>[];

  for (final v in vehicles) {
    if (v.deletedAt != null || v.status != 'active') continue;

    if (v.insuranceExpiry != null) {
      final days = v.insuranceExpiry!.difference(now).inDays;
      alerts.add(ExpiryAlert(
        vehicleId: v.id,
        vehicleRegNo: v.regNo,
        type: 'insurance',
        expiryDate: v.insuranceExpiry!,
        daysLeft: days,
      ));
    }
    if (v.fitnessExpiry != null) {
      final days = v.fitnessExpiry!.difference(now).inDays;
      alerts.add(ExpiryAlert(
        vehicleId: v.id,
        vehicleRegNo: v.regNo,
        type: 'fitness',
        expiryDate: v.fitnessExpiry!,
        daysLeft: days,
      ));
    }
    if (v.taxExpiry != null) {
      final days = v.taxExpiry!.difference(now).inDays;
      alerts.add(ExpiryAlert(
        vehicleId: v.id,
        vehicleRegNo: v.regNo,
        type: 'tax',
        expiryDate: v.taxExpiry!,
        daysLeft: days,
      ));
    }
  }

  alerts.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  return ExpiryAlerts(alerts: alerts);
}