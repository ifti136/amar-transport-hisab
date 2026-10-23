import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/features/backup/backup_service.dart';
import 'package:transport_hisab/features/backup/restore_service.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/settings/opening_balances_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Create Backup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.createBackup, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Create a complete backup of all your data including vehicles, drivers, customers, trips, expenses, fuel records, loans, and settings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _createBackup(context, ref),
                    icon: const Icon(Icons.backup),
                    label: Text(l10n.createBackup),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Restore
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.restoreTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Restore your data from a backup file. This will replace ALL your current data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _restoreBackup(context, ref),
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.restoreTitle),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final file = await BackupService.createBackup(ref.read(databaseProvider));

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupSuccess(file.path))),
        );
        // Prompt user to share or save outside device
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Amar Transport Hisab Backup',
          text: 'Backup file for Amar Transport Hisab',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Pick backup file
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: l10n.selectBackupFile,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) return;

      final file = File(pickerResult.files.single.path!);

      // Validate and preview
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final restoreResult = await RestoreService.restoreFromFile(ref.read(databaseProvider), file);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (!restoreResult.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore validation failed: ${restoreResult.error}')),
          );
        }
        return;
      }

      // Show preview dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.restoreConfirm),
              const SizedBox(height: 16),
              Text(l10n.restorePreview(restoreResult.recordCounts!.values.fold(0, (a, b) => a + b), restoreResult.backupTimestamp ?? 'Unknown')),
              const SizedBox(height: 16),
              Text('Records to restore:', style: Theme.of(context).textTheme.titleSmall),
              ...restoreResult.recordCounts!.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.restoreButton),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Perform restore
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await RestoreService.performRestore(ref.read(databaseProvider), file);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ref.invalidate(dashboardProvider);
        ref.invalidate(allOpeningBalancesProvider);
        ref.invalidate(activeVehiclesProvider);
        ref.invalidate(activeDriversProvider);
        ref.invalidate(activeCustomersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
}