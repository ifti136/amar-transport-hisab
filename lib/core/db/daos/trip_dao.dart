import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/trips.dart';
import '../tables/expenses.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class TripDao extends BaseDao<Trips, TripsCompanion> {
  TripDao(super.db, super.audit) : super(tableName: 'trips');

  @override
  TableInfo get table => db.trips;

  @override
  Map<String, dynamic> companionToMap(TripsCompanion companion) {
    return {
      'vehicle_id': companion.vehicleId.valueOrNull,
      'driver_id': companion.driverId.valueOrNull,
      'customer_id': companion.customerId.valueOrNull,
      'custom_customer_name': companion.customCustomerName.valueOrNull,
      'trip_date': companion.tripDate.valueOrNull?.toIso8601String(),
      'agreed_fare_paisa': companion.agreedFarePaisa.valueOrNull,
      'advance_paisa': companion.advancePaisa.valueOrNull,
      'start_odo': companion.startOdo.valueOrNull,
      'end_odo': companion.endOdo.valueOrNull,
      'status': companion.status.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> rowToMap(dynamic row) {
    return {
      'id': row.id,
      'vehicle_id': row.vehicleId,
      'driver_id': row.driverId,
      'customer_id': row.customerId,
      'custom_customer_name': row.customCustomerName,
      'trip_date': row.tripDate.toIso8601String(),
      'agreed_fare_paisa': row.agreedFarePaisa,
      'advance_paisa': row.advancePaisa,
      'start_odo': row.startOdo,
      'end_odo': row.endOdo,
      'status': row.status,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get trips with filters
  Stream<List<Trip>> watchTrips({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? customerId,
    int? driverId,
    String? status,
  }) {
    var query = db.select(db.trips)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.tripDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.tripDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }
    if (customerId != null) {
      query = query..where((t) => t.customerId.equals(customerId));
    }
    if (driverId != null) {
      query = query..where((t) => t.driverId.equals(driverId));
    }
    if (status != null) {
      query = query..where((t) => t.status.equals(status));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.tripDate), (t) => OrderingTerm.desc(t.id)]);
    return query.watch();
  }

  Future<List<Trip>> getTrips({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? customerId,
    int? driverId,
    String? status,
  }) async {
    var query = db.select(db.trips)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.tripDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.tripDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }
    if (customerId != null) {
      query = query..where((t) => t.customerId.equals(customerId));
    }
    if (driverId != null) {
      query = query..where((t) => t.driverId.equals(driverId));
    }
    if (status != null) {
      query = query..where((t) => t.status.equals(status));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.tripDate), (t) => OrderingTerm.desc(t.id)]);
    return query.get();
  }

  // Get trip with outstanding
  Future<TripWithOutstanding?> getTripWithOutstanding(int tripId) async {
    final trip = await getById(tripId);
    if (trip == null) return null;

    final payments = await (db.select(db.customerPayments)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull()))
        .get();

    final totalPaid = payments.fold(0, (sum, p) => sum + p.amountPaisa);
    final outstanding = trip.agreedFarePaisa - trip.advancePaisa - totalPaid;

    return TripWithOutstanding(
      trip: trip,
      totalPaid: totalPaid,
      outstanding: outstanding,
    );
  }

  // Get trips with outstanding > 0 for a customer
  Future<List<TripWithOutstanding>> getTripsWithOutstandingForCustomer(int customerId) async {
    final trips = await (db.select(db.trips)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.deletedAt.isNull() &
              t.status.equals('completed')))
        .get();

    final result = <TripWithOutstanding>[];
    for (final trip in trips) {
      final payments = await (db.select(db.customerPayments)
            ..where((t) => t.tripId.equals(trip.id) & t.deletedAt.isNull()))
          .get();
      final totalPaid = payments.fold(0, (sum, p) => sum + p.amountPaisa);
      final outstanding = trip.agreedFarePaisa - trip.advancePaisa - totalPaid;
      if (outstanding > 0) {
        result.add(TripWithOutstanding(
          trip: trip,
          totalPaid: totalPaid,
          outstanding: outstanding,
        ));
      }
    }
    return result;
  }

  // Get trip profit (fare - expenses)
  Future<int> getTripProfit(int tripId) async {
    final trip = await getById(tripId);
    if (trip == null) return 0;

    final expenses = await (db.select(db.expenses)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull()))
        .get();

    final totalExpenses = expenses.fold(0, (sum, e) => sum + e.amountPaisa);
    return trip.agreedFarePaisa - totalExpenses;
  }
}

class TripWithOutstanding {
  final Trip trip;
  final int totalPaid;
  final int outstanding;

  TripWithOutstanding({
    required this.trip,
    required this.totalPaid,
    required this.outstanding,
  });
}