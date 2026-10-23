import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/customer_dao.dart';
import 'package:transport_hisab/core/db/daos/trip_dao.dart';
import 'package:transport_hisab/core/db/daos/customer_payment_dao.dart';

/// Customer DAO provider
final customerDaoProvider = Provider<CustomerDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return CustomerDao(db, audit);
});

/// Trip DAO provider
final tripDaoProvider = Provider<TripDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return TripDao(db, audit);
});

/// Customer Payment DAO provider
final customerPaymentDaoProvider = Provider<CustomerPaymentDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return CustomerPaymentDao(db, audit);
});

/// Stream of active customers
final activeCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final dao = ref.watch(customerDaoProvider);
  return dao.watchActiveCustomers();
});

/// Stream of trips with filters
final tripsProvider = StreamProvider.family<List<Trip>, TripFilter>((ref, filter) {
  final dao = ref.watch(tripDaoProvider);
  return dao.watchTrips(
    from: filter.from,
    to: filter.to,
    vehicleId: filter.vehicleId,
    customerId: filter.customerId,
    driverId: filter.driverId,
    status: filter.status,
  );
});

/// Trip filter class
class TripFilter {
  final DateTime? from;
  final DateTime? to;
  final int? vehicleId;
  final int? customerId;
  final int? driverId;
  final String? status;

  const TripFilter({
    this.from,
    this.to,
    this.vehicleId,
    this.customerId,
    this.driverId,
    this.status,
  });

  TripFilter copyWith({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? customerId,
    int? driverId,
    String? status,
  }) {
    return TripFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      vehicleId: vehicleId ?? this.vehicleId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
    );
  }
}

/// Provider for trip with outstanding
final tripWithOutstandingProvider = FutureProvider.family<TripWithOutstanding?, int>((ref, tripId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getTripWithOutstanding(tripId);
});

/// Provider for trips with outstanding for a customer
final tripsWithOutstandingForCustomerProvider = FutureProvider.family<List<TripWithOutstanding>, int>((ref, customerId) async {
  final dao = ref.watch(tripDaoProvider);
  return dao.getTripsWithOutstandingForCustomer(customerId);
});

/// Provider for customer ledger
final customerLedgerProvider = FutureProvider.family<List<CustomerLedgerEntry>, CustomerLedgerFilter>((ref, filter) async {
  final dao = ref.watch(customerDaoProvider);
  return dao.getCustomerLedger(filter.customerId, filter.from, filter.to);
});

class CustomerLedgerFilter {
  final int customerId;
  final DateTime from;
  final DateTime to;

  const CustomerLedgerFilter({
    required this.customerId,
    required this.from,
    required this.to,
  });
}