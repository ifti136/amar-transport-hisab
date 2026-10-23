import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/app_lock_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/trips/trips_screen.dart';
import 'features/trips/trip_form.dart';
import 'features/money/expenses_screen.dart';
import 'features/money/expense_form.dart';
import 'features/money/fuel_form.dart';
import 'features/vehicles/vehicles_screen.dart';
import 'features/vehicles/all_loans_screen.dart';
import 'features/drivers/drivers_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/opening_balances_screen.dart';
import 'features/backup/backup_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider with persistent bottom navigation shell and root sub-routes
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trips',
                name: 'trips',
                builder: (context, state) => const TripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                name: 'money',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Legacy /more redirect
      GoRoute(
        path: '/more',
        redirect: (context, state) => '/settings',
      ),
      // Sub-routes pushed on top of root navigator with top back button
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/trips/add',
        builder: (context, state) => const TripForm(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/expenses/add',
        builder: (context, state) => const ExpenseForm(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/fuel/add',
        builder: (context, state) => const FuelForm(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/vehicles',
        builder: (context, state) => const VehiclesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/drivers',
        builder: (context, state) => const DriversScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/loans',
        builder: (context, state) => const AllLoansScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/opening-balances',
        builder: (context, state) => const OpeningBalancesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/backup',
        builder: (context, state) => const BackupScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Amar Transport Hisab')), // i18n-ignore
      body: Center(
        child: Text(AppLocalizations.of(context)!.pageNotFound(state.error.toString())),
      ),
    ),
  );
});

/// Persistent shell bottom navigation
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: l10n.tripsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.moneyTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}

/// App wrapper with theme, localization and AppLockOverlay
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
      builder: (context, child) {
        return AppLockOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Overlay that guards the app behind biometrics/PIN when app lock is active
class AppLockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final isLockEnabled = ref.read(appLockEnabledProvider);
      if (isLockEnabled) {
        _checkAndPromptAuth();
      }
    }
  }

  Future<void> _checkAndPromptAuth() async {
    final isLockEnabled = ref.read(appLockEnabledProvider);
    final isUnlocked = ref.read(appUnlockedProvider);

    if (isLockEnabled && !isUnlocked) {
      final auth = ref.read(appLockServiceProvider);
      final success = await auth.authenticate();
      if (success && mounted) {
        ref.read(appUnlockedProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockEnabled = ref.watch(appLockEnabledProvider);
    final isUnlocked = ref.watch(appUnlockedProvider);

    if (!isLockEnabled || isUnlocked) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context)!;
    final title = l10n.appTitle;
    final lockedText = l10n.appLocked;
    final buttonText = l10n.authenticateButton;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lockedText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _checkAndPromptAuth,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(buttonText),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
