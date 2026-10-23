import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/vehicle_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';

/// Vehicle DAO provider
final vehicleDaoProvider = Provider<VehicleDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return VehicleDao(db, audit);
});

/// Stream of active vehicles
final activeVehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.watchActiveVehicles();
});

/// Stream of all vehicles (including inactive)
final allVehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.watchAllVehicles();
});

/// Future provider for vehicles with expiring documents
final expiringVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.getVehiclesWithExpiringDocs();
});

/// Provider for vehicle expiry days
final vehicleExpiryProvider = FutureProvider.family<Map<String, int?>, int>((ref, vehicleId) async {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.getExpiryDays(vehicleId);
});

/// Provider for last odometer
final lastOdometerProvider = FutureProvider.family<int?, int>((ref, vehicleId) async {
  final dao = ref.watch(vehicleDaoProvider);
  return dao.getLastOdometer(vehicleId);
});