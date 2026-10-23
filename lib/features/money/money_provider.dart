import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/expense_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'package:transport_hisab/core/services/photo_service.dart';

/// Expense DAO provider
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return ExpenseDao(db, audit);
});

/// Fuel DAO provider
final fuelDaoProvider = Provider<FuelDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return FuelDao(db, audit);
});

/// Photo Service provider
final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());

/// Stream of expenses with filters
final expensesProvider = StreamProvider.family<List<Expense>, ExpenseFilter>((ref, filter) {
  final dao = ref.watch(expenseDaoProvider);
  return dao.watchExpenses(
    from: filter.from,
    to: filter.to,
    vehicleId: filter.vehicleId,
    tripId: filter.tripId,
    category: filter.category,
  );
});

/// Expense filter class
class ExpenseFilter {
  final DateTime? from;
  final DateTime? to;
  final int? vehicleId;
  final int? tripId;
  final String? category;

  const ExpenseFilter({
    this.from,
    this.to,
    this.vehicleId,
    this.tripId,
    this.category,
  });

  ExpenseFilter copyWith({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? tripId,
    String? category,
  }) {
    return ExpenseFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      vehicleId: vehicleId ?? this.vehicleId,
      tripId: tripId ?? this.tripId,
      category: category ?? this.category,
    );
  }
}

/// Stream of fuel records with filters
final fuelRecordsProvider = StreamProvider.family<List<FuelRecord>, FuelFilter>((ref, filter) {
  final dao = ref.watch(fuelDaoProvider);
  return dao.watchFuelRecords(
    from: filter.from,
    to: filter.to,
    vehicleId: filter.vehicleId,
  );
});

/// Fuel filter class
class FuelFilter {
  final DateTime? from;
  final DateTime? to;
  final int? vehicleId;

  const FuelFilter({
    this.from,
    this.to,
    this.vehicleId,
  });

  FuelFilter copyWith({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
  }) {
    return FuelFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }
}

/// Provider for fuel consumption
final fuelConsumptionProvider = FutureProvider.family<FuelConsumption?, FuelConsumptionFilter>((ref, filter) async {
  final dao = ref.watch(fuelDaoProvider);
  return dao.getFuelConsumption(filter.vehicleId, filter.from, filter.to);
});

class FuelConsumptionFilter {
  final int vehicleId;
  final DateTime from;
  final DateTime to;

  const FuelConsumptionFilter({
    required this.vehicleId,
    required this.from,
    required this.to,
  });
}