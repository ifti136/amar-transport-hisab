// Van Monthly P&L Result
class VanMonthlyPnL {
  final int vehicleId;
  final int year;
  final int month;
  final int revenuePaisa;
  final Map<String, int> expensesByCategoryPaisa;
  final int totalExpensesPaisa;
  final int loanInterestPaisa;
  final int depreciationPaisa; // Always 0 per PRD
  final int profitPaisa;

  VanMonthlyPnL({
    required this.vehicleId,
    required this.year,
    required this.month,
    required this.revenuePaisa,
    required this.expensesByCategoryPaisa,
    required this.totalExpensesPaisa,
    required this.loanInterestPaisa,
    required this.depreciationPaisa,
    required this.profitPaisa,
  });

  int get totalExpensesWithInterestPaisa => totalExpensesPaisa + loanInterestPaisa + depreciationPaisa;

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'year': year,
    'month': month,
    'revenuePaisa': revenuePaisa,
    'expensesByCategoryPaisa': expensesByCategoryPaisa,
    'totalExpensesPaisa': totalExpensesPaisa,
    'loanInterestPaisa': loanInterestPaisa,
    'depreciationPaisa': depreciationPaisa,
    'profitPaisa': profitPaisa,
  };
}

// Cash Flow Result
class CashFlow {
  final int year;
  final int month;
  final int openingCashPaisa;
  final int cashReceivedPaisa;
  final int cashPaidPaisa;
  final int closingCashPaisa;
  final Map<String, int> receiptsByTypePaisa;
  final Map<String, int> paymentsByTypePaisa;

  CashFlow({
    required this.year,
    required this.month,
    required this.openingCashPaisa,
    required this.cashReceivedPaisa,
    required this.cashPaidPaisa,
    required this.closingCashPaisa,
    required this.receiptsByTypePaisa,
    required this.paymentsByTypePaisa,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'openingCashPaisa': openingCashPaisa,
    'cashReceivedPaisa': cashReceivedPaisa,
    'cashPaidPaisa': cashPaidPaisa,
    'closingCashPaisa': closingCashPaisa,
    'receiptsByTypePaisa': receiptsByTypePaisa,
    'paymentsByTypePaisa': paymentsByTypePaisa,
  };
}

// Customer Ledger Result
class CustomerLedger {
  final int customerId;
  final DateTime from;
  final DateTime to;
  final int openingBalancePaisa;
  final List<CustomerLedgerEntry> entries;
  final int closingBalancePaisa;

  CustomerLedger({
    required this.customerId,
    required this.from,
    required this.to,
    required this.openingBalancePaisa,
    required this.entries,
    required this.closingBalancePaisa,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'openingBalancePaisa': openingBalancePaisa,
    'entries': entries.map((e) => e.toJson()).toList(),
    'closingBalancePaisa': closingBalancePaisa,
  };
}

class CustomerLedgerEntry {
  final DateTime date;
  final String type; // 'opening_balance', 'trip', 'payment'
  final String description;
  final int amountPaisa; // Positive = increases outstanding, Negative = decreases
  final int balancePaisa;

  CustomerLedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.amountPaisa,
    required this.balancePaisa,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'type': type,
    'description': description,
    'amountPaisa': amountPaisa,
    'balancePaisa': balancePaisa,
  };
}

// Driver Ledger Result
class DriverLedger {
  final int driverId;
  final DateTime from;
  final DateTime to;
  final List<DriverLedgerEntry> entries;
  final int closingBalancePaisa;

  DriverLedger({
    required this.driverId,
    required this.from,
    required this.to,
    required this.entries,
    required this.closingBalancePaisa,
  });

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'closingBalancePaisa': closingBalancePaisa,
  };
}

class DriverLedgerEntry {
  final DateTime date;
  final String type; // 'salary_earned', 'salary_paid', 'advance_given', 'advance_deducted', 'loan_given', 'loan_repaid'
  final String description;
  final int amountPaisa; // Positive = increases driver balance, Negative = decreases
  final int balancePaisa;

  DriverLedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.amountPaisa,
    required this.balancePaisa,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'type': type,
    'description': description,
    'amountPaisa': amountPaisa,
    'balancePaisa': balancePaisa,
  };
}

// Trip Register Result
class TripRegister {
  final DateTime from;
  final DateTime to;
  final int? vehicleId;
  final List<TripRegisterEntry> entries;
  final int totalFarePaisa;
  final int totalAdvancePaisa;
  final int totalOutstandingPaisa;

  TripRegister({
    required this.from,
    required this.to,
    this.vehicleId,
    required this.entries,
    required this.totalFarePaisa,
    required this.totalAdvancePaisa,
    required this.totalOutstandingPaisa,
  });

  Map<String, dynamic> toJson() => {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'vehicleId': vehicleId,
    'entries': entries.map((e) => e.toJson()).toList(),
    'totalFarePaisa': totalFarePaisa,
    'totalAdvancePaisa': totalAdvancePaisa,
    'totalOutstandingPaisa': totalOutstandingPaisa,
  };
}

class TripRegisterEntry {
  final int tripId;
  final DateTime date;
  final String customerName;
  final String vehicleRegNo;
  final int farePaisa;
  final int advancePaisa;
  final int outstandingPaisa;

  TripRegisterEntry({
    required this.tripId,
    required this.date,
    required this.customerName,
    required this.vehicleRegNo,
    required this.farePaisa,
    required this.advancePaisa,
    required this.outstandingPaisa,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'vehicleRegNo': vehicleRegNo,
    'farePaisa': farePaisa,
    'advancePaisa': advancePaisa,
    'outstandingPaisa': outstandingPaisa,
  };
}

// Expense Register Result
class ExpenseRegister {
  final DateTime from;
  final DateTime to;
  final int? vehicleId;
  final String? category;
  final List<ExpenseRegisterEntry> entries;
  final Map<String, int> totalsByCategoryPaisa;
  final int grandTotalPaisa;

  ExpenseRegister({
    required this.from,
    required this.to,
    this.vehicleId,
    this.category,
    required this.entries,
    required this.totalsByCategoryPaisa,
    required this.grandTotalPaisa,
  });

  Map<String, dynamic> toJson() => {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'vehicleId': vehicleId,
    'category': category,
    'entries': entries.map((e) => e.toJson()).toList(),
    'totalsByCategoryPaisa': totalsByCategoryPaisa,
    'grandTotalPaisa': grandTotalPaisa,
  };
}

class ExpenseRegisterEntry {
  final int expenseId;
  final DateTime date;
  final String category;
  final String vehicleRegNo;
  final int? tripId;
  final int amountPaisa;

  ExpenseRegisterEntry({
    required this.expenseId,
    required this.date,
    required this.category,
    required this.vehicleRegNo,
    this.tripId,
    required this.amountPaisa,
  });

  Map<String, dynamic> toJson() => {
    'expenseId': expenseId,
    'date': date.toIso8601String(),
    'category': category,
    'vehicleRegNo': vehicleRegNo,
    'tripId': tripId,
    'amountPaisa': amountPaisa,
  };
}

// Fuel Register Result
class FuelRegister {
  final DateTime from;
  final DateTime to;
  final int? vehicleId;
  final List<FuelRegisterEntry> entries;
  final double totalLitres;
  final int totalCostPaisa;
  final double avgKmPerLitre;

  FuelRegister({
    required this.from,
    required this.to,
    this.vehicleId,
    required this.entries,
    required this.totalLitres,
    required this.totalCostPaisa,
    required this.avgKmPerLitre,
  });

  Map<String, dynamic> toJson() => {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'vehicleId': vehicleId,
    'entries': entries.map((e) => e.toJson()).toList(),
    'totalLitres': totalLitres,
    'totalCostPaisa': totalCostPaisa,
    'avgKmPerLitre': avgKmPerLitre,
  };
}

class FuelRegisterEntry {
  final int fuelId;
  final DateTime date;
  final String vehicleRegNo;
  final double litres;
  final int ratePerLitrePaisa;
  final int totalPaisa;
  final int odometer;
  final double? kmPerLitre;

  FuelRegisterEntry({
    required this.fuelId,
    required this.date,
    required this.vehicleRegNo,
    required this.litres,
    required this.ratePerLitrePaisa,
    required this.totalPaisa,
    required this.odometer,
    this.kmPerLitre,
  });

  Map<String, dynamic> toJson() => {
    'fuelId': fuelId,
    'date': date.toIso8601String(),
    'vehicleRegNo': vehicleRegNo,
    'litres': litres,
    'ratePerLitrePaisa': ratePerLitrePaisa,
    'totalPaisa': totalPaisa,
    'odometer': odometer,
    'kmPerLitre': kmPerLitre,
  };
}

// Loan Schedule Result
class LoanSchedule {
  final int vehicleId;
  final List<LoanScheduleEntry> entries;

  LoanSchedule({
    required this.vehicleId,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

class LoanScheduleEntry {
  final int loanId;
  final DateTime date;
  final int totalPaidPaisa;
  final int principalPaisa;
  final int interestPaisa;
  final int outstandingPaisa;

  LoanScheduleEntry({
    required this.loanId,
    required this.date,
    required this.totalPaidPaisa,
    required this.principalPaisa,
    required this.interestPaisa,
    required this.outstandingPaisa,
  });

  Map<String, dynamic> toJson() => {
    'loanId': loanId,
    'date': date.toIso8601String(),
    'totalPaidPaisa': totalPaidPaisa,
    'principalPaisa': principalPaisa,
    'interestPaisa': interestPaisa,
    'outstandingPaisa': outstandingPaisa,
  };
}

// Expiry Alerts Result
class ExpiryAlerts {
  final List<ExpiryAlert> alerts;

  ExpiryAlerts({required this.alerts});

  Map<String, dynamic> toJson() => {
    'alerts': alerts.map((e) => e.toJson()).toList(),
  };
}

class ExpiryAlert {
  final int vehicleId;
  final String vehicleRegNo;
  final String type; // 'insurance', 'fitness', 'tax'
  final DateTime expiryDate;
  final int daysLeft;

  ExpiryAlert({
    required this.vehicleId,
    required this.vehicleRegNo,
    required this.type,
    required this.expiryDate,
    required this.daysLeft,
  });

  String get status {
    if (daysLeft <= 0) return 'expired';
    if (daysLeft <= 7) return 'critical';
    if (daysLeft <= 30) return 'warning';
    return 'ok';
  }

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'vehicleRegNo': vehicleRegNo,
    'type': type,
    'expiryDate': expiryDate.toIso8601String(),
    'daysLeft': daysLeft,
    'status': status,
  };
}