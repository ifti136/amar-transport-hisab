import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drivers.dart';
import '../tables/driver_transactions.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'base_dao.dart';

class DriverDao extends BaseDao<Drivers, DriversCompanion> {
  DriverDao(super.db, super.audit) : super(tableName: 'drivers');

  @override
  TableInfo get table => db.drivers;

  @override
  Map<String, dynamic> companionToMap(DriversCompanion companion) {
    return {
      'name': companion.name.valueOrNull,
      'phone': companion.phone.valueOrNull,
      'monthly_salary_paisa': companion.monthlySalaryPaisa.valueOrNull,
      'status': companion.status.valueOrNull,
      'joined_date': companion.joinedDate.valueOrNull?.toIso8601String(),
      'created_at': companion.createdAt.valueOrNull?.toIso8601String(),
      'updated_at': companion.updatedAt.valueOrNull?.toIso8601String(),
      'deleted_at': companion.deletedAt.valueOrNull?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> rowToMap(dynamic row) {
    return {
      'id': row.id,
      'name': row.name,
      'phone': row.phone,
      'monthly_salary_paisa': row.monthlySalaryPaisa,
      'status': row.status,
      'joined_date': row.joinedDate.toIso8601String(),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
      'deleted_at': row.deletedAt?.toIso8601String(),
    };
  }

  // Get active drivers
  Stream<List<Driver>> watchActiveDrivers() {
    return (db.select(db.drivers)
          ..where((t) => t.deletedAt.isNull() & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Driver>> getActiveDrivers() async {
    return (db.select(db.drivers)
          ..where((t) => t.deletedAt.isNull() & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  // Get all drivers including inactive
  Stream<List<Driver>> watchAllDrivers() {
    return (db.select(db.drivers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  // Check if salary_earned exists for a driver in a given month
  Future<bool> hasSalaryEarnedForMonth(int driverId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await (db.select(db.driverTransactions)
          ..where((t) =>
              t.driverId.equals(driverId) &
              t.deletedAt.isNull() &
              t.type.equals('salary_earned') &
              t.transactionDate.isBiggerOrEqualValue(startOfMonth) &
              t.transactionDate.isSmallerOrEqualValue(endOfMonth)))
        .get();

    return result.isNotEmpty;
  }
}