import 'dart:convert';
import 'dart:io';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/features/backup/backup_service.dart';

class RestoreService {
  /// Restore from backup file with validation and preview
  static Future<RestoreResult> restoreFromFile(AppDatabase db, File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = backupData['version'] as String?;
      if (version != BackupService.backupVersion) {
        return RestoreResult(
          success: false,
          error: 'Incompatible backup version: $version (expected ${BackupService.backupVersion})',
        );
      }

      // Validate required tables
      final requiredTables = [
        'vehicles', 'drivers', 'customers', 'trips', 'customer_payments',
        'expenses', 'fuel_records', 'driver_transactions', 'vehicle_loans',
        'loan_installments', 'audit_log', 'app_settings'
      ];

      for (final table in requiredTables) {
        if (!backupData.containsKey(table)) {
          return RestoreResult(
            success: false,
            error: 'Missing table in backup: $table',
          );
        }
      }

      // Count records for preview
      final recordCounts = <String, int>{};
      for (final table in [
        'vehicles', 'drivers', 'customers', 'trips', 'customer_payments',
        'expenses', 'fuel_records', 'driver_transactions', 'vehicle_loans',
        'loan_installments', 'audit_log', 'app_settings'
      ]) {
        final data = backupData[table] as List?;
        recordCounts[table] = data?.length ?? 0;
      }

      return RestoreResult(
        success: true,
        recordCounts: recordCounts,
        backupTimestamp: backupData['timestamp'] as String?,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        error: 'Failed to read backup file: $e',
      );
    }
  }

  /// Perform the actual restore
  static Future<void> performRestore(AppDatabase db, File backupFile) async {
    // Restore data in transaction (pre-restore snapshot is created inside restoreBackup)
    await BackupService.restoreBackup(db, backupFile);
  }
}

class RestoreResult {
  final bool success;
  final String? error;
  final Map<String, int>? recordCounts;
  final String? backupTimestamp;

  RestoreResult({
    required this.success,
    this.error,
    this.recordCounts,
    this.backupTimestamp,
  });
}
