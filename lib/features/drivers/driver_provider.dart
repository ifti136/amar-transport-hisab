import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/db/daos/driver_dao.dart';
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'package:transport_hisab/core/services/salary_accrual_service.dart';
import 'package:transport_hisab/features/drivers/driver_account_provider.dart';

/// Driver DAO provider
final driverDaoProvider = Provider<DriverDao>((ref) {
  final db = ref.watch(databaseProvider);
  final audit = ref.watch(auditServiceProvider);
  return DriverDao(db, audit);
});

/// Stream of active drivers
final activeDriversProvider = StreamProvider<List<Driver>>((ref) {
  final dao = ref.watch(driverDaoProvider);
  return dao.watchActiveDrivers();
});

/// Stream of all drivers (including inactive)
final allDriversProvider = StreamProvider<List<Driver>>((ref) {
  final dao = ref.watch(driverDaoProvider);
  return dao.watchAllDrivers();
});

/// Salary Accrual Service provider
final salaryAccrualServiceProvider = Provider<SalaryAccrualService>((ref) {
  final db = ref.watch(databaseProvider);
  final driverDao = ref.watch(driverDaoProvider);
  final transactionDao = ref.watch(driverTransactionDaoProvider);
  return SalaryAccrualService(db, driverDao, transactionDao);
});

/// Provider to trigger salary accrual on app start
final salaryAccrualTriggerProvider = FutureProvider<void>((ref) async {
  try {
    final service = ref.watch(salaryAccrualServiceProvider);
    await service.ensureMonthlySalaryAccrued();
  } catch (_) {
    // Salary accrual must never block app startup.
  }
});