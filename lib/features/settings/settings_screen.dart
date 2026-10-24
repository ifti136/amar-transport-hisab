import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_hisab/core/localization/locale_provider.dart';
import 'package:transport_hisab/core/theme/theme_provider.dart';
import 'package:transport_hisab/core/services/app_lock_service.dart';
import 'package:transport_hisab/core/services/expiry_alert_service.dart';
import 'package:transport_hisab/core/services/cloud_backup_service.dart';
import 'package:transport_hisab/core/services/business_name_provider.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final expiryAlertsEnabled = ref.watch(expiryAlertsEnabledProvider);
    final expiryAlerts = ref.watch(vehicleExpiryAlertsListProvider);
    final cloudBackupEnabled = ref.watch(cloudBackupEnabledProvider);
    final lastCloudSync = ref.watch(cloudBackupLastSyncProvider);
    final businessName = ref.watch(businessNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 0: Business Profile
          _SectionHeader(title: l10n.businessNameLabel),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.business, size: 28),
              title: Text(
                businessName.isNotEmpty ? businessName : l10n.appTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.businessNameDesc),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _showEditBusinessNameDialog(context, ref, businessName),
            ),
          ),

          // Section 1: Appearance & Language
          _SectionHeader(title: l10n.languageLabel),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.languageLabel, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'bn', label: Text('বাংলা')), // i18n-ignore
                      ButtonSegment(value: 'en', label: Text('English')), // i18n-ignore
                    ],
                    selected: {currentLocale.languageCode},
                    onSelectionChanged: (set) {
                      ref.read(localeProvider.notifier).setLocale(Locale(set.first));
                    },
                  ),
                  const Divider(height: 24),
                  Text(l10n.themeLabel, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(l10n.themeDark),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(l10n.themeSystem),
                      ),
                    ],
                    selected: {currentTheme},
                    onSelectionChanged: (set) {
                      ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Section 2: Financial Opening Balances
          _SectionHeader(title: l10n.openingBalancesLabel),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, size: 28),
              title: Text(l10n.openingBalancesLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${l10n.openingCashLabel}, ${l10n.customerOpeningLabel}, ${l10n.driverOpeningLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/opening-balances'),
            ),
          ),

          // Section 3: Security & App Lock
          _SectionHeader(title: l10n.appLockLabel),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint, size: 28),
              title: Text(l10n.appLockLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.appLockDesc),
              value: appLockEnabled,
              onChanged: (val) async {
                final authService = ref.read(appLockServiceProvider);
                final authenticated = await authService.authenticate(
                  localizedReason: l10n.unlockReason,
                );
                if (authenticated) {
                  await ref.read(appLockEnabledProvider.notifier).setEnabled(val);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Authentication failed or cancelled')), // i18n-ignore
                  );
                }
              },
            ),
          ),

          // Section 4: Document Expiry Alerts
          _SectionHeader(title: l10n.notificationsLabel),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, size: 28),
                  title: Text(l10n.notificationsLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.notificationsDesc),
                  value: expiryAlertsEnabled,
                  onChanged: (val) {
                    ref.read(expiryAlertsEnabledProvider.notifier).setEnabled(val);
                  },
                ),
                if (expiryAlertsEnabled && expiryAlerts.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${expiryAlerts.length} ${l10n.reportExpiryAlerts}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...expiryAlerts.take(3).map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.regNo} - ${item.documentType}'), // i18n-ignore
                                Text(
                                  item.isExpired
                                      ? 'Expired (${item.expiryDate})'
                                      : '${item.daysRemaining} days left',
                                  style: TextStyle(
                                    color: item.isExpired ? Colors.red : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (expiryAlerts.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${expiryAlerts.length - 3} more in Reports',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Section 5: Backup & Cloud
          _SectionHeader(title: l10n.backupTitle),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined, size: 28),
                  title: Text(l10n.backupTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Export database or restore from previous backup file'), // i18n-ignore
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/backup'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_upload_outlined, size: 28),
                  title: Text(l10n.cloudBackupLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    lastCloudSync != null
                        ? '${l10n.cloudBackupDesc} (Last: $lastCloudSync)'
                        : l10n.cloudBackupDesc,
                  ),
                  value: cloudBackupEnabled,
                  onChanged: (val) {
                    ref.read(cloudBackupEnabledProvider.notifier).setEnabled(val);
                  },
                ),
                if (cloudBackupEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_outlined),
                            label: Text(l10n.cloudBackupExport),
                            onPressed: () async {
                              try {
                                await CloudBackupService.exportEncryptedCloudBackup(ref);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Export failed: $e')), // i18n-ignore
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Section 6: Fleet & Management Shortcuts
          _SectionHeader(title: l10n.moreTab),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(l10n.vehiclesNavLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/vehicles'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_pin_outlined),
                  title: Text(l10n.driversNavLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/drivers'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(l10n.customersNavLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/customers'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(l10n.loansNavLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/loans'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: Text(l10n.reportsNavLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.expenseCategoriesTitle),
                  subtitle: Text(l10n.expenseCategoriesDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/expense-categories'),
                ),
              ],
            ),
          ),

          // Section 7: App Feature Walkthrough
          _SectionHeader(title: l10n.walkthroughTitle),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.help_outline, size: 28),
              title: Text(l10n.walkthroughTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.walkthroughDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/onboarding'),
            ),
          ),

          // Section 8: About Section (Clean Sub-section)
          _SectionHeader(title: l10n.aboutTitle),
          Card(
            margin: const EdgeInsets.only(bottom: 32),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png', // i18n-ignore
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(l10n.aboutTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Amar Transport Hisab v0.3.0 • Iftekharul Islam'), // i18n-ignore
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/about'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.businessNameLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.businessNameLabel,
            hintText: l10n.businessNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              await ref.read(businessNameProvider.notifier).setBusinessName(newName);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                AppToast.showSuccess(context, l10n.businessNameSaved);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
