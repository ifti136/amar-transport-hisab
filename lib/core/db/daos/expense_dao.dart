import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/expenses.dart';
import '../tables/fuel_records.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class ExpenseDao extends BaseDao<Expenses, ExpensesCompanion> {
  ExpenseDao(super.db, super.audit) : super(tableName: 'expenses');

  @override
  TableInfo get table => db.expenses;

  @override
  Map<String, dynamic> companionToMap(ExpensesCompanion companion) {
    return {
      'vehicle_id': companion.vehicleId.valueOrNull,
      'trip_id': companion.tripId.valueOrNull,
      'category': companion.category.valueOrNull,
      'amount_paisa': companion.amountPaisa.valueOrNull,
      'expense_date': companion.expenseDate.valueOrNull?.toIso8601String(),
      'note': companion.note.valueOrNull,
      'photo_path': companion.photoPath.valueOrNull,
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
      'trip_id': row.tripId,
      'category': row.category,
      'amount_paisa': row.amountPaisa,
      'expense_date': row.expenseDate.toIso8601String(),
      'note': row.note,
      'photo_path': row.photoPath,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  @override
  Future<Expense?> getById(int id) async {
    return (db.select(db.expenses)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  // Get expenses with filters
  Stream<List<Expense>> watchExpenses({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? tripId,
    String? category,
  }) {
    var query = db.select(db.expenses)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.expenseDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.expenseDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }
    if (tripId != null) {
      query = query..where((t) => t.tripId.equals(tripId));
    }
    if (category != null) {
      query = query..where((t) => t.category.equals(category));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.expenseDate), (t) => OrderingTerm.desc(t.id)]);
    return query.watch();
  }

  Future<List<Expense>> getExpenses({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
    int? tripId,
    String? category,
  }) async {
    var query = db.select(db.expenses)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.expenseDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.expenseDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }
    if (tripId != null) {
      query = query..where((t) => t.tripId.equals(tripId));
    }
    if (category != null) {
      query = query..where((t) => t.category.equals(category));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.expenseDate), (t) => OrderingTerm.desc(t.id)]);
    return query.get();
  }

  // Get expenses for a trip
  Future<List<Expense>> getExpensesForTrip(int tripId) async {
    return (db.select(db.expenses)
          ..where((t) => t.tripId.equals(tripId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.expenseDate)]))
        .get();
  }

  // Get total expenses for a vehicle in a period
  Future<int> getTotalExpensesForVehicle(int vehicleId, DateTime from, DateTime to) async {
    final expenses = await (db.select(db.expenses)
          ..where((t) =>
              t.vehicleId.equals(vehicleId) &
              t.deletedAt.isNull() &
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();
    return expenses.fold<int>(0, (sum, e) => sum + e.amountPaisa);
  }

  // Get expenses by category for a vehicle in a period
  Future<Map<String, int>> getExpensesByCategory(int vehicleId, DateTime from, DateTime to) async {
    final expenses = await (db.select(db.expenses)
          ..where((t) =>
              t.vehicleId.equals(vehicleId) &
              t.deletedAt.isNull() &
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();

    final result = <String, int>{};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amountPaisa;
    }
    return result;
  }
}

class FuelDao extends BaseDao<FuelRecords, FuelRecordsCompanion> {
  FuelDao(super.db, super.audit) : super(tableName: 'fuel_records');

  @override
  TableInfo get table => db.fuelRecords;

  @override
  Map<String, dynamic> companionToMap(FuelRecordsCompanion companion) {
    return {
      'vehicle_id': companion.vehicleId.valueOrNull,
      'expense_id': companion.expenseId.valueOrNull,
      'litres': companion.litres.valueOrNull,
      'rate_per_litre_paisa': companion.ratePerLitrePaisa.valueOrNull,
      'odometer': companion.odometer.valueOrNull,
      'fuel_date': companion.fuelDate.valueOrNull?.toIso8601String(),
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
      'expense_id': row.expenseId,
      'litres': row.litres,
      'rate_per_litre_paisa': row.ratePerLitrePaisa,
      'odometer': row.odometer,
      'fuel_date': row.fuelDate.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get fuel records with filters
  Stream<List<FuelRecord>> watchFuelRecords({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
  }) {
    var query = db.select(db.fuelRecords)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.fuelDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.fuelDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.fuelDate), (t) => OrderingTerm.desc(t.id)]);
    return query.watch();
  }

  Future<List<FuelRecord>> getFuelRecords({
    DateTime? from,
    DateTime? to,
    int? vehicleId,
  }) async {
    var query = db.select(db.fuelRecords)..where((t) => t.deletedAt.isNull());

    if (from != null) {
      query = query..where((t) => t.fuelDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query = query..where((t) => t.fuelDate.isSmallerOrEqualValue(to));
    }
    if (vehicleId != null) {
      query = query..where((t) => t.vehicleId.equals(vehicleId));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.fuelDate), (t) => OrderingTerm.desc(t.id)]);
    return query.get();
  }

  // Get last fuel record for a vehicle (for odometer)
  Future<FuelRecord?> getLastFuelRecord(int vehicleId) async {
    return (db.select(db.fuelRecords)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.fuelDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Get fuel record for an expense
  Future<FuelRecord?> getFuelRecordByExpenseId(int expenseId) async {
    return (db.select(db.fuelRecords)
          ..where((t) => t.expenseId.equals(expenseId) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  // Get fuel consumption for a vehicle in a period
  Future<FuelConsumption?> getFuelConsumption(int vehicleId, DateTime from, DateTime to) async {
    final records = await (db.select(db.fuelRecords)
          ..where((t) =>
              t.vehicleId.equals(vehicleId) &
              t.deletedAt.isNull() &
              t.fuelDate.isBiggerOrEqualValue(from) &
              t.fuelDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.fuelDate)]))
        .get();

    if (records.length < 2) return null;

    double totalLitres = 0;
    int totalKm = 0;
    int totalCostPaisa = 0;

    for (int i = 1; i < records.length; i++) {
      final prev = records[i - 1];
      final curr = records[i];
      final km = curr.odometer - prev.odometer;
      if (km > 0) {
        totalKm += km;
        totalLitres += curr.litres;
        totalCostPaisa += (curr.ratePerLitrePaisa * curr.litres).round();
      }
    }

    if (totalLitres == 0) return null;

    return FuelConsumption(
      totalLitres: totalLitres,
      totalKm: totalKm,
      totalCostPaisa: totalCostPaisa,
      kmPerLitre: totalKm / totalLitres,
      costPerKm: totalCostPaisa / totalKm,
    );
  }
}

class FuelConsumption {
  final double totalLitres;
  final int totalKm;
  final int totalCostPaisa;
  final double kmPerLitre;
  final double costPerKm;

  FuelConsumption({
    required this.totalLitres,
    required this.totalKm,
    required this.totalCostPaisa,
    required this.kmPerLitre,
    required this.costPerKm,
  });
}