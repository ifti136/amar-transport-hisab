import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/trips',
        name: 'trips',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: '/money',
        name: 'money',
        builder: (context, state) => const MoneyScreen(),
      ),
      GoRoute(
        path: '/more',
        name: 'more',
        builder: (context, state) => const MoreScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context)!.pageNotFound(state.error.toString())),
      ),
    ),
  );
});

/// App wrapper that provides theme based on themeModeProvider
class AmarTransportHisabApp extends ConsumerWidget {
  const AmarTransportHisabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isBn = locale.languageCode == 'bn';

    return MaterialApp.router(
      title: 'Amar Transport Hisab', // i18n-ignore: OS task switcher title
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme(isBn),
      darkTheme: darkTheme(isBn),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Placeholder screens for M0/M0b
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              ref.read(localeProvider.notifier).toggle();
            },
            tooltip: l10n.languageToggle,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Text(l10n.scaffoldHome),
            const SizedBox(height: 8),
            Text(l10n.currentLocale(Localizations.localeOf(context).languageCode)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/trips');
              break;
            case 2:
              context.go('/money');
              break;
            case 3:
              context.go('/more');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.tripsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.moneyTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.moreTab,
          ),
        ],
      ),
    );
  }
}

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripsTab)),
      body: Center(child: Text(l10n.scaffoldTrips)),
    );
  }
}

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moneyTab)),
      body: Center(child: Text(l10n.scaffoldMoney)),
    );
  }
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTab)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Toggle
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.themeLabel),
              subtitle: Text(_themeModeLabel(l10n, themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings'),
            ),
          ),
          const SizedBox(height: 8),
          // Language Toggle
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.languageLabel),
              subtitle: Text(Localizations.localeOf(context).languageCode == 'bn' ? 'বাংলা' : 'English'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(localeProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 8),
          // Placeholder for other settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.openingBalancesLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to opening balances
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.backupTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to backup
              },
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Text(l10n.themeLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeLabel(l10n, mode)),
              value: mode,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            );
          }),
          const Divider(height: 32),
          // Language Section
          Text(l10n.languageLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(Localizations.localeOf(context).languageCode == 'bn' ? 'বাংলা' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(localeProvider.notifier).toggle();
            },
          ),
          const Divider(height: 32),
          // Opening Balances
          Text(l10n.openingBalancesLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l10n.openingCashLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to opening cash
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: Text(l10n.customerOpeningLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to customer opening balances
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(l10n.driverOpeningLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to driver opening balances
            },
          ),
          const Divider(height: 32),
          // Backup Section
          Text(l10n.backupTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.createBackup),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to backup
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text(l10n.restoreTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to restore
            },
          ),
          const Divider(height: 32),
          // App Lock (Could - off by default)
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: Text(l10n.appLockLabel),
            subtitle: Text(l10n.appLockDesc),
            value: false, // TODO: Read from settings
            onChanged: (value) {
              // TODO: Implement app lock
            },
          ),
          // Notifications (Could - off by default)
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notificationsLabel),
            subtitle: Text(l10n.notificationsDesc),
            value: false, // TODO: Read from settings
            onChanged: (value) {
              // TODO: Implement notifications
            },
          ),
          // Cloud Backup (Could - off by default)
          SwitchListTile(
            secondary: const Icon(Icons.cloud_upload_outlined),
            title: Text(l10n.cloudBackupLabel),
            subtitle: Text(l10n.cloudBackupDesc),
            value: false, // TODO: Read from settings
            onChanged: (value) {
              // TODO: Implement cloud backup
            },
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }
}