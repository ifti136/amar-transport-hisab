import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/vehicles.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class VehicleDao extends BaseDao<Vehicles, VehiclesCompanion> {
  VehicleDao(super.db, super.audit) : super(tableName: 'vehicles');

  @override
  TableInfo get table => db.vehicles;

  @override
  Map<String, dynamic> _companionToMap(VehiclesCompanion companion) {
    return {
      'reg_no': companion.regNo.valueOrNull,
      'type': companion.type.valueOrNull,
      'insurance_expiry': companion.insuranceExpiry.valueOrNull?.toIso8601String(),
      'fitness_expiry': companion.fitnessExpiry.valueOrNull?.toIso8601String(),
      'tax_expiry': companion.taxExpiry.valueOrNull?.toIso8601String(),
      'status': companion.status.valueOrNull,
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row.id,
      'reg_no': row.regNo,
      'type': row.type,
      'insurance_expiry': row.insuranceExpiry?.toIso8601String(),
      'fitness_expiry': row.fitnessExpiry?.toIso8601String(),
      'tax_expiry': row.taxExpiry?.toIso8601String(),
      'status': row.status,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get active vehicles (not soft deleted)
  Stream<List<Vehicle>> watchActiveVehicles() {
    return (db.select(db.vehicles)
          ..where((t) => t.deletedAt.isNull() & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.regNo)]))
        .watch();
  }

  Future<List<Vehicle>> getActiveVehicles() async {
    return (db.select(db.vehicles)
          ..where((t) => t.deletedAt.isNull() & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.regNo)]))
        .get();
  }

  // Get all vehicles including inactive
  Stream<List<Vehicle>> watchAllVehicles() {
    return (db.select(db.vehicles)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.regNo)]))
        .watch();
  }

  // Get last odometer reading for a vehicle
  Future<int?> getLastOdometer(int vehicleId) async {
    // Check trips for end_odo
    final tripOdo = await (db.select(db.trips)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull() & t.endOdo.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.tripDate)])
          ..limit(1))
        .getSingleOrNull();

    if (tripOdo?.endOdo != null) return tripOdo!.endOdo;

    // Check fuel records for odometer
    final fuelOdo = await (db.select(db.fuelRecords)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.fuelDate)])
          ..limit(1))
        .getSingleOrNull();

    return fuelOdo?.odometer;
  }

  // Get expiry status for a vehicle
  Future<Map<String, int?>> getExpiryDays(int vehicleId) async {
    final vehicle = await getById(vehicleId);
    if (vehicle == null) return {};

    final now = DateTime.now();
    return {
      'insurance': vehicle.insuranceExpiry != null
          ? (vehicle.insuranceExpiry as DateTime).difference(now).inDays
          : null,
      'fitness': vehicle.fitnessExpiry != null
          ? (vehicle.fitnessExpiry as DateTime).difference(now).inDays
          : null,
      'tax': vehicle.taxExpiry != null
          ? (vehicle.taxExpiry as DateTime).difference(now).inDays
          : null,
    };
  }

  // Get vehicles with expiring documents (≤30 days)
  Future<List<Vehicle>> getVehiclesWithExpiringDocs() async {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));

    return (db.select(db.vehicles)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.status.equals('active') &
              ((t.insuranceExpiry.isNotNull() & t.insuranceExpiry.isSmallerOrEqualValue(thirtyDaysLater)) |
                  (t.fitnessExpiry.isNotNull() & t.fitnessExpiry.isSmallerOrEqualValue(thirtyDaysLater)) |
                  (t.taxExpiry.isNotNull() & t.taxExpiry.isSmallerOrEqualValue(thirtyDaysLater)))))
        .get();
  }
}