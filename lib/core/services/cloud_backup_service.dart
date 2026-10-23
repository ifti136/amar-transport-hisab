import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/features/backup/backup_service.dart';

const String _kCloudBackupKey = 'cloud_backup_enabled';
const String _kCloudBackupLastSyncKey = 'cloud_backup_last_sync';

class CloudBackupEnabledNotifier extends StateNotifier<bool> {
  CloudBackupEnabledNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kCloudBackupKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCloudBackupKey, enabled);
    state = enabled;
  }
}

final cloudBackupEnabledProvider = StateNotifierProvider<CloudBackupEnabledNotifier, bool>((ref) {
  return CloudBackupEnabledNotifier();
});

class CloudBackupLastSyncNotifier extends StateNotifier<String?> {
  CloudBackupLastSyncNotifier() : super(null) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kCloudBackupLastSyncKey);
  }

  Future<void> updateSyncTimestamp() async {
    final timestamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCloudBackupLastSyncKey, timestamp);
    state = timestamp;
  }
}

final cloudBackupLastSyncProvider = StateNotifierProvider<CloudBackupLastSyncNotifier, String?>((ref) {
  return CloudBackupLastSyncNotifier();
});

class CloudBackupService {
  /// Prepares an encrypted backup file and invokes the native system share/export sheet
  /// allowing upload to Google Drive, Cloud, or email.
  static Future<File> exportEncryptedCloudBackup(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final backupFile = await BackupService.createBackup(db);

    // Update last sync time
    await ref.read(cloudBackupLastSyncProvider.notifier).updateSyncTimestamp();

    // Trigger system share sheet for cloud upload
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      subject: 'Amar Transport Hisab Encrypted Backup',
      text: 'Encrypted database backup for Amar Transport Hisab',
    );

    return backupFile;
  }
}

