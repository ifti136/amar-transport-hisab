import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/settings/opening_balances_provider.dart';
import 'package:transport_hisab/core/db/tables/customers.dart';
import 'package:transport_hisab/core/db/tables/drivers.dart';

class OpeningBalancesScreen extends ConsumerWidget {
  const OpeningBalancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allBalancesAsync = ref.watch(allOpeningBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openingBalancesLabel)),
      body: allBalancesAsync.when(
        data: (balances) {
          final cash = balances['cash'] as int;
          final customers = balances['customers'] as Map<int, int>;
          final drivers = balances['drivers'] as Map<int, int>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Opening Cash
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.openingCashLabel, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatMoney(Money.paisa(cash), context: context),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: cash >= 0
                                  ? Theme.of(context).extension<AppSemanticColors>()!.success
                                  : Theme.of(context).extension<AppSemanticColors>()!.danger,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _editOpeningCash(context, ref, cash),
                            icon: const Icon(Icons.edit),
                            label: Text(l10n.edit),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Opening Balances
              Text(l10n.customerOpeningLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (customers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noCustomerOpeningBalances, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ...customers.entries.map((entry) => _CustomerOpeningBalanceTile(
                      customerId: entry.key,
                      amount: entry.value,
                    )),

              const SizedBox(height: 16),

              // Driver Opening Balances
              Text(l10n.driverOpeningLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (drivers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noDriverOpeningBalances, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ...drivers.entries.map((entry) => _DriverOpeningBalanceTile(
                      driverId: entry.key,
                      amount: entry.value,
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorLoadingBalances(error.toString()))),
      ),
    );
  }

  void _editOpeningCash(BuildContext context, WidgetRef ref, int currentAmount) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: (currentAmount / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.openingCashLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.openingCashLabel,
            prefixText: '৳ ',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(openingBalancesDaoProvider);
              final amount = (double.parse(controller.text) * 100).round();
              await dao.setOpeningCash(amount);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(allOpeningBalancesProvider);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _CustomerOpeningBalanceTile extends ConsumerWidget {
  final int customerId;
  final int amount;

  const _CustomerOpeningBalanceTile({required this.customerId, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.customerIdLabel(customerId)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(Money.paisa(amount), context: context)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCustomerOpeningBalance(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _editCustomerOpeningBalance(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: (amount / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customerOpeningLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.customerOpeningLabel, prefixText: '৳ '),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(openingBalancesDaoProvider);
              final newAmount = (double.parse(controller.text) * 100).round();
              await dao.setCustomerOpeningBalance(customerId, newAmount);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(allOpeningBalancesProvider);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _DriverOpeningBalanceTile extends ConsumerWidget {
  final int driverId;
  final int amount;

  const _DriverOpeningBalanceTile({required this.driverId, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.directions_car_outlined),
        title: Text(l10n.driverIdLabel(driverId)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(Money.paisa(amount), context: context)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editDriverOpeningBalance(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _editDriverOpeningBalance(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: (amount / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.driverOpeningLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.driverOpeningLabel, prefixText: '৳ '),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(openingBalancesDaoProvider);
              final newAmount = (double.parse(controller.text) * 100).round();
              await dao.setDriverOpeningBalance(driverId, newAmount);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(allOpeningBalancesProvider);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}