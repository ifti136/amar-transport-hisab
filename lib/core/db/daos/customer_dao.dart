import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/customers.dart';
import '../tables/trips.dart';
import '../tables/customer_payments.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class CustomerDao extends BaseDao<Customers, CustomersCompanion> {
  CustomerDao(super.db, super.audit) : super(tableName: 'customers');

  @override
  TableInfo get table => db.customers;

  @override
  Map<String, dynamic> _companionToMap(CustomersCompanion companion) {
    return {
      'name': companion.name.valueOrNull,
      'phone': companion.phone.valueOrNull,
      'opening_balance_paisa': companion.openingBalancePaisa.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row.id,
      'name': row.name,
      'phone': row.phone,
      'opening_balance_paisa': row.openingBalancePaisa,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get active customers
  Stream<List<Customer>> watchActiveCustomers() {
    return (db.select(db.customers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Customer>> getActiveCustomers() async {
    return (db.select(db.customers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  // Get customer with outstanding balance
  Future<int> getCustomerOutstanding(int customerId, DateTime upTo) async {
    final customer = await getById(customerId);
    if (customer == null) return 0;

    final openingBalance = customer.openingBalancePaisa;

    // Sum of trip fares
    final tripFares = await (db.select(db.trips)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.status.equals('completed') &
              t.tripDate.isSmallerOrEqualValue(upTo)))
        .get();

    final totalFares = tripFares.fold(0, (sum, t) => sum + t.agreedFarePaisa);

    // Sum of payments
    final payments = await (db.select(db.customerPayments)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.paymentDate.isSmallerOrEqualValue(upTo)))
        .get();

    final totalPayments = payments.fold(0, (sum, t) => sum + t.amountPaisa);

    return openingBalance + totalFares - totalPayments;
  }

  // Get customer ledger entries
  Future<List<CustomerLedgerEntry>> getCustomerLedger(int customerId, DateTime from, DateTime to) async {
    final customer = await getById(customerId);
    if (customer == null) return [];

    final entries = <CustomerLedgerEntry>[];

    // Opening balance
    if (customer.openingBalancePaisa != 0) {
      entries.add(CustomerLedgerEntry(
        date: from,
        type: 'opening_balance',
        description: 'Opening Balance',
        amount: customer.openingBalancePaisa,
        balance: customer.openingBalancePaisa,
      ));
    }

    // Trips (revenue)
    final trips = await (db.select(db.trips)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.status.equals('completed') &
              t.tripDate.isBiggerOrEqualValue(from) &
              t.tripDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.tripDate)]))
        .get();

    for (final trip in trips) {
      entries.add(CustomerLedgerEntry(
        date: trip.tripDate,
        type: 'trip',
        description: 'Trip #${trip.id} (${trip.vehicleId})',
        amount: trip.agreedFarePaisa,
        balance: 0, // Will compute running balance
      ));
    }

    // Payments
    final payments = await (db.select(db.customerPayments)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.paymentDate.isBiggerOrEqualValue(from) &
              t.paymentDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.paymentDate)]))
        .get();

    for (final payment in payments) {
      entries.add(CustomerLedgerEntry(
        date: payment.paymentDate,
        type: 'payment',
        description: 'Payment received',
        amount: -payment.amountPaisa, // Negative = reduces outstanding
        balance: 0,
      ));
    }

    // Sort by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Compute running balance
    int runningBalance = customer.openingBalancePaisa;
    for (final entry in entries) {
      runningBalance += entry.amount;
      entry.balance = runningBalance;
    }

    return entries;
  }
}

class CustomerLedgerEntry {
  final DateTime date;
  final String type;
  final String description;
  final int amount; // Positive = increases outstanding, Negative = decreases
  int balance;

  CustomerLedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.balance,
  });
}