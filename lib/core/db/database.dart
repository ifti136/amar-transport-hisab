import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:transport_hisab/core/audit/audit_log.dart';
import 'tables/vehicles.dart';
import 'tables/drivers.dart';
import 'tables/customers.dart';
import 'tables/trips.dart';
import 'tables/customer_payments.dart';
import 'tables/expenses.dart';
import 'tables/fuel_records.dart';
import 'tables/driver_transactions.dart';
import 'tables/vehicle_loans.dart';
import 'tables/loan_installments.dart';
import 'tables/audit_log.dart';
import 'tables/app_settings.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Vehicles,
  Drivers,
  Customers,
  Trips,
  CustomerPayments,
  Expenses,
  FuelRecords,
  DriverTransactions,
  VehicleLoans,
  LoanInstallments,
  AuditLog,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Vehicle indexes
      await customStatement('CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_vehicles_insurance_expiry ON vehicles(insurance_expiry)');
      // Trips indexes
      await customStatement('CREATE INDEX IF NOT EXISTS idx_trips_vehicle_date ON trips(vehicle_id, trip_date)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_trips_customer_date ON trips(customer_id, trip_date)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_trips_driver_date ON trips(driver_id, trip_date)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_trips_status_date ON trips(status, trip_date)');
      // Expenses indexes
      await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_date ON expenses(vehicle_id, expense_date)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_trip ON expenses(trip_id)');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_category_date ON expenses(category, expense_date)');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        final tripCols = await customSelect('PRAGMA table_info(trips)').get();
        final hasCustomName = tripCols.any((row) => row.data['name'] == 'custom_customer_name');

        if (!hasCustomName) {
          await m.alterTable(TableMigration(
            trips,
            newColumns: [trips.customCustomerName],
            columnTransformer: {
              trips.customCustomerName: const CustomExpression<String>('NULL'),
            },
          ));
        } else {
          await m.alterTable(TableMigration(trips));
        }
        await m.alterTable(TableMigration(customerPayments));
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'amar_transport_hisab.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final auditServiceProvider = Provider<AuditService>((ref) {
  final db = ref.watch(databaseProvider);
  return AuditService(db);
});

extension ValueExtension<T> on Value<T> {
  T? get valueOrNull => present ? value : null;
}
