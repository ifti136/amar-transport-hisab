import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/drivers/driver_account_provider.dart';

class GiveAdvanceSheet extends ConsumerStatefulWidget {
  final Driver driver;

  const GiveAdvanceSheet({super.key, required this.driver});

  @override
  ConsumerState<GiveAdvanceSheet> createState() => _GiveAdvanceSheetState();
}

class _GiveAdvanceSheetState extends ConsumerState<GiveAdvanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.giveAdvanceTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Driver Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.driver.name, style: theme.textTheme.titleMedium),
                          Text(l10n.outstandingAdvanceLabel(formatMoney(Money.paisa(0), context: context)), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)), // TODO: Load actual outstanding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                hintText: l10n.advanceAmountHint,
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorPositiveAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteLabel,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaisa = (double.parse(_amountController.text) * 100).round();

    final dao = ref.read(driverTransactionDaoProvider);
    await dao.insertWithAudit(DriverTransactionsCompanion.insert(
      driverId: widget.driver.id,
      type: 'advance_given',
      amountPaisa: amountPaisa,
      transactionDate: DateTime.now(),
      note: Value(_noteController.text.trim().isEmpty ? 'Advance given' : _noteController.text.trim()),
    ), userNote: 'Advance given to driver');

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(driverTransactionsProvider(widget.driver.id));
      ref.invalidate(driverBalanceProvider(DriverBalanceFilter(driverId: widget.driver.id, upTo: DateTime.now())));
      ref.invalidate(outstandingAdvanceProvider(OutstandingAdvanceFilter(driverId: widget.driver.id, upTo: DateTime.now())));
    }
  }
}