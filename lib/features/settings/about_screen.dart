import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo & Title
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png', // i18n-ignore
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amar Transport Hisab', // i18n-ignore
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'আমার ট্রান্সপোর্ট হিসাব', // i18n-ignore
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version v0.2.0 (Build 3)', // i18n-ignore
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aboutTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l10n.appAboutDesc, style: theme.textTheme.bodyMedium),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.help_outline),
                    title: const Text('App Feature Walkthrough'), // i18n-ignore
                    subtitle: const Text('View intro guide and onboarding tutorial'), // i18n-ignore
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/onboarding'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer & Project Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Developer & Project', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), // i18n-ignore
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Developer', value: 'Iftekharul Islam (ifti136)'), // i18n-ignore
                  _InfoRow(label: 'Platform', value: 'Android (100% Offline)'), // i18n-ignore
                  _InfoRow(label: 'Database', value: 'Encrypted SQLite (Drift)'), // i18n-ignore
                  _InfoRow(label: 'License', value: 'MIT Open Source License'), // i18n-ignore
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Version Changelog
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Version History & Updates', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), // i18n-ignore
                  const SizedBox(height: 12),
                  _ChangelogItem(
                    version: 'v0.2.0 (Latest)', // i18n-ignore
                    date: 'October 2026', // i18n-ignore
                    changes: const [
                      'Distance input (km) in place of start/end odometer for trips',
                      'Dual expense tracking: Trip Expense vs Vehicle Expense',
                      'Customizable Expense Categories in Settings',
                      'Removed odometer requirement from fuel entry',
                      'Multi-click prevention and confirmation notices for all forms',
                      'Fixed continuous loading in Trip, Expense, and Fuel reports',
                      'Integrated official transport van app logo',
                      'Streamlined settings with dedicated About sub-section',
                    ],
                  ),
                  const Divider(height: 20),
                  _ChangelogItem(
                    version: 'v0.1.0', // i18n-ignore
                    date: 'October 2026', // i18n-ignore
                    changes: const [
                      'Persistent bottom navigation across tabs',
                      'Dedicated settings with inline Language & Theme toggles',
                      'Biometric and PIN app lock security',
                      'Vehicle document expiration alerts',
                      'Full financial report suite with PDF & Excel exports',
                      'Reliable local encrypted database backup & restore',
                    ],
                  ),
                  const Divider(height: 20),
                  _ChangelogItem(
                    version: 'v0.0.1 (Initial)', // i18n-ignore
                    date: 'October 2026', // i18n-ignore
                    changes: const [
                      'Core SQLite schema, 64-bit integer paisa accounting engine',
                      'Bengali numeral parsing and Lakh/Crore BDT currency formatting',
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  final String version;
  final String date;
  final List<String> changes;

  const _ChangelogItem({
    required this.version,
    required this.date,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(version, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(date, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        ...changes.map((c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)), // i18n-ignore
              Expanded(child: Text(c, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        )),
      ],
    );
  }
}
