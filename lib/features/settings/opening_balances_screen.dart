import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/settings/opening_balances_provider.dart';
import 'package:transport_hisab/features/customers/customer_provider.dart';
import 'package:transport_hisab/features/drivers/driver_provider.dart';

class OpeningBalancesScreen extends ConsumerWidget {
  const OpeningBalancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allBalancesAsync = ref.watch(allOpeningBalancesProvider);
    final customersAsync = ref.watch(activeCustomersProvider);
    final driversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openingBalancesLabel)),
      body: allBalancesAsync.when(
        data: (balances) {
          final cash = balances['cash'] as int? ?? 0;
          final driverBalances = (balances['drivers'] as Map<int, int>?) ?? <int, int>{};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Opening Cash Card
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
                          Expanded(
                            child: Text(
                              formatMoney(Money.paisa(cash), context: context),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: cash >= 0
                                        ? Theme.of(context).extension<AppSemanticColors>()?.success
                                        : Theme.of(context).extension<AppSemanticColors>()?.danger,
                                  ),
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
              const SizedBox(height: 24),

              // Customer Opening Balances Header
              Text(
                l10n.customerOpeningLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noCustomerOpeningBalances, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    );
                  }
                  return Column(
                    children: customers.map((customer) {
                      final amount = customer.openingBalancePaisa;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(customer.phone ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatMoney(Money.paisa(amount), context: context),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amount > 0
                                      ? Theme.of(context).extension<AppSemanticColors>()?.danger
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.edit,
                                onPressed: () => _editCustomerOpeningBalance(
                                  context,
                                  ref,
                                  customer.id,
                                  customer.name,
                                  amount,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(e.toString()),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Driver Opening Balances Header
              Text(
                l10n.driverOpeningLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              driversAsync.when(
                data: (drivers) {
                  if (drivers.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noDriverOpeningBalances, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    );
                  }
                  return Column(
                    children: drivers.map((driver) {
                      final amount = driverBalances[driver.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.directions_car_outlined),
                          ),
                          title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(driver.phone ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatMoney(Money.paisa(amount), context: context),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amount > 0
                                      ? Theme.of(context).extension<AppSemanticColors>()?.warning
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.edit,
                                onPressed: () => _editDriverOpeningBalance(
                                  context,
                                  ref,
                                  driver.id,
                                  driver.name,
                                  amount,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(e.toString()),
                  ),
                ),
              ),
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
    final controller = TextEditingController(
      text: currentAmount == 0 ? '' : (currentAmount / 100).toStringAsFixed(2),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text(l10n.openingCashLabel),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.openingCashLabel,
              prefixText: '৳ ',
              errorText: errorText,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                int paisa = 0;
                if (text.isNotEmpty) {
                  final parsed = parseMoneyInput(text);
                  switch (parsed) {
                    case Success(:final value):
                      paisa = value.paisa;
                    case Failure(:final error):
                      setState(() => errorText = error);
                      return;
                  }
                }
                final dao = ref.read(openingBalancesDaoProvider);
                await dao.setOpeningCash(paisa);
                ref.invalidate(allOpeningBalancesProvider);
                ref.invalidate(openingCashProvider);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _editCustomerOpeningBalance(
    BuildContext context,
    WidgetRef ref,
    int customerId,
    String customerName,
    int currentAmount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: currentAmount == 0 ? '' : (currentAmount / 100).toStringAsFixed(2),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text('${l10n.customerOpeningLabel}: $customerName'), // i18n-ignore
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.customerOpeningLabel,
              prefixText: '৳ ',
              errorText: errorText,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                int paisa = 0;
                if (text.isNotEmpty) {
                  final parsed = parseMoneyInput(text);
                  switch (parsed) {
                    case Success(:final value):
                      paisa = value.paisa;
                    case Failure(:final error):
                      setState(() => errorText = error);
                      return;
                  }
                }
                final dao = ref.read(openingBalancesDaoProvider);
                await dao.setCustomerOpeningBalance(customerId, paisa);
                ref.invalidate(allOpeningBalancesProvider);
                ref.invalidate(customerOpeningBalancesProvider);
                ref.invalidate(activeCustomersProvider);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _editDriverOpeningBalance(
    BuildContext context,
    WidgetRef ref,
    int driverId,
    String driverName,
    int currentAmount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: currentAmount == 0 ? '' : (currentAmount / 100).toStringAsFixed(2),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text('${l10n.driverOpeningLabel}: $driverName'), // i18n-ignore
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.driverOpeningLabel,
              prefixText: '৳ ',
              errorText: errorText,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                int paisa = 0;
                if (text.isNotEmpty) {
                  final parsed = parseMoneyInput(text);
                  switch (parsed) {
                    case Success(:final value):
                      paisa = value.paisa;
                    case Failure(:final error):
                      setState(() => errorText = error);
                      return;
                  }
                }
                final dao = ref.read(openingBalancesDaoProvider);
                await dao.setDriverOpeningBalance(driverId, paisa);
                ref.invalidate(allOpeningBalancesProvider);
                ref.invalidate(driverOpeningBalancesProvider);
                ref.invalidate(activeDriversProvider);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
