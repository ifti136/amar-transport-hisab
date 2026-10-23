import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:transport_hisab/core/db/database.dart';

/// Backup service for local backup/restore
class BackupService {
  static const String backupVersion = '1.0';
  static const String _backupPrefix = 'AmarTransportHisab_backup_';

  /// Create a backup of all data
  static Future<File> createBackup(AppDatabase db) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${dir.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = '$_backupPrefix$timestamp.json';
    final file = File('${backupsDir.path}/$fileName');

    // Fetch all data
    final vehicles = await db.select(db.vehicles).get();
    final drivers = await db.select(db.drivers).get();
    final customers = await db.select(db.customers).get();
    final trips = await db.select(db.trips).get();
    final customerPayments = await db.select(db.customerPayments).get();
    final expenses = await db.select(db.expenses).get();
    final fuelRecords = await db.select(db.fuelRecords).get();
    final driverTransactions = await db.select(db.driverTransactions).get();
    final vehicleLoans = await db.select(db.vehicleLoans).get();
    final loanInstallments = await db.select(db.loanInstallments).get();
    final auditLog = await db.select(db.auditLog).get();
    final appSettings = await db.select(db.appSettings).get();

    final backupData = {
      'version': backupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'drivers': drivers.map((d) => d.toJson()).toList(),
      'customers': customers.map((c) => c.toJson()).toList(),
      'trips': trips.map((t) => t.toJson()).toList(),
      'customer_payments': customerPayments.map((p) => p.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'fuel_records': fuelRecords.map((f) => f.toJson()).toList(),
      'driver_transactions': driverTransactions.map((dt) => dt.toJson()).toList(),
      'vehicle_loans': vehicleLoans.map((vl) => vl.toJson()).toList(),
      'loan_installments': loanInstallments.map((li) => li.toJson()).toList(),
      'audit_log': auditLog.map((al) => al.toJson()).toList(),
      'app_settings': appSettings.map((s) => s.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    await file.writeAsString(jsonString);

    return file;
  }

  /// Restore from backup file
  static Future<void> restoreBackup(AppDatabase db, File backupFile) async {
    final jsonString = await backupFile.readAsString();
    final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validate version
    final version = backupData['version'] as String?;
    if (version != backupVersion) {
      throw Exception('Incompatible backup version: $version (expected $backupVersion)');
    }

    // Validate required tables
    final requiredTables = [
      'vehicles', 'drivers', 'customers', 'trips', 'customer_payments',
      'expenses', 'fuel_records', 'driver_transactions', 'vehicle_loans',
      'loan_installments', 'audit_log', 'app_settings'
    ];

    for (final table in requiredTables) {
      if (!backupData.containsKey(table)) {
        throw Exception('Missing table in backup: $table');
      }
    }

    // Create pre-restore snapshot
    await createPreRestoreSnapshot();

    // Restore data in transaction
    await db.transaction(() async {
      // Clear existing data (in reverse dependency order)
      await db.delete(db.loanInstallments).go();
      await db.delete(db.vehicleLoans).go();
      await db.delete(db.driverTransactions).go();
      await db.delete(db.fuelRecords).go();
      await db.delete(db.expenses).go();
      await db.delete(db.customerPayments).go();
      await db.delete(db.trips).go();
      await db.delete(db.customers).go();
      await db.delete(db.drivers).go();
      await db.delete(db.vehicles).go();
      await db.delete(db.auditLog).go();
      await db.delete(db.appSettings).go();

      // Restore data (in dependency order)
      for (final r in (backupData['app_settings'] as List? ?? [])) {
        await db.into(db.appSettings).insert(AppSetting.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['vehicles'] as List? ?? [])) {
        await db.into(db.vehicles).insert(Vehicle.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['drivers'] as List? ?? [])) {
        await db.into(db.drivers).insert(Driver.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['customers'] as List? ?? [])) {
        await db.into(db.customers).insert(Customer.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['trips'] as List? ?? [])) {
        await db.into(db.trips).insert(Trip.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['customer_payments'] as List? ?? [])) {
        await db.into(db.customerPayments).insert(CustomerPayment.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['expenses'] as List? ?? [])) {
        await db.into(db.expenses).insert(Expense.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['fuel_records'] as List? ?? [])) {
        await db.into(db.fuelRecords).insert(FuelRecord.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['driver_transactions'] as List? ?? [])) {
        await db.into(db.driverTransactions).insert(DriverTransaction.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['vehicle_loans'] as List? ?? [])) {
        await db.into(db.vehicleLoans).insert(VehicleLoan.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['loan_installments'] as List? ?? [])) {
        await db.into(db.loanInstallments).insert(LoanInstallment.fromJson(Map<String, dynamic>.from(r as Map)));
      }
      for (final r in (backupData['audit_log'] as List? ?? [])) {
        await db.into(db.auditLog).insert(AuditLogData.fromJson(Map<String, dynamic>.from(r as Map)));
      }
    });
  }

  static Future<void> createPreRestoreSnapshot() async {
    // Create a snapshot of current data before restore
    // This is a safety measure in case restore fails
    final dir = await getApplicationDocumentsDirectory();
    final snapshotDir = Directory('${dir.path}/snapshots');
    if (!await snapshotDir.exists()) {
      await snapshotDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final file = File('${snapshotDir.path}/pre_restore_$timestamp.json');
    
    // This would be implemented with actual DB dump
    // For now, just create an empty marker file
    await file.writeAsString('{}');
  }
}