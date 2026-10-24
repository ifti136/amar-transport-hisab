import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/drivers/driver_account_provider.dart';

class DriverLoanSheet extends ConsumerStatefulWidget {
  final Driver driver;

  const DriverLoanSheet({super.key, required this.driver});

  @override
  ConsumerState<DriverLoanSheet> createState() => _DriverLoanSheetState();
}

class _DriverLoanSheetState extends ConsumerState<DriverLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'loan_given'; // loan_given or loan_repaid
  bool _isSaving = false;

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
    final loanBalanceAsync = ref.watch(driverLoanBalanceProvider(widget.driver.id));
    final loanBalancePaisa = loanBalanceAsync.asData?.value ?? 0;

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
            Text(l10n.driverLoanTitle, style: theme.textTheme.headlineSmall),
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
                          Text(
                            l10n.loanBalanceLabel(formatMoney(Money.paisa(loanBalancePaisa), context: context)),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type Selector
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'loan_given',
                  label: Text(l10n.loanGivenLabel),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                ButtonSegment(
                  value: 'loan_repaid',
                  label: Text(l10n.loanRepaidLabel),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: _type == 'loan_given' ? l10n.loanGivenLabel : l10n.loanRepaidLabel,
                hintText: l10n.loanAmountHint,
                prefixText: '৳ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return l10n.errorInvalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: _type == 'loan_given' ? 'Loan given to driver' : 'Loan repaid by driver',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_type == 'loan_given' ? l10n.loanGivenLabel : l10n.loanRepaidLabel),
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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final amtRes = parseMoneyInput(_amountController.text);
    final amountPaisa = amtRes is Success ? amtRes.value.paisa : 0;
    if (amountPaisa <= 0) return;

    setState(() => _isSaving = true);

    try {
      final dao = ref.read(driverTransactionDaoProvider);
      await dao.insertWithAudit(DriverTransactionsCompanion.insert(
        driverId: widget.driver.id,
        type: _type,
        amountPaisa: amountPaisa,
        transactionDate: DateTime.now(),
        note: Value(_noteController.text.trim().isEmpty
            ? (_type == 'loan_given' ? 'Loan given to driver' : 'Loan repaid by driver')
            : _noteController.text.trim()),
      ), userNote: _type == 'loan_given' ? 'Loan given to driver' : 'Loan repaid by driver');

      if (mounted) {
        AppToast.showSuccess(context, l10n.driverLoanSuccess);
        Navigator.pop(context);
        ref.invalidate(driverTransactionsProvider(widget.driver.id));
        ref.invalidate(driverBalanceProvider(DriverBalanceFilter(driverId: widget.driver.id, upTo: DateTime.now())));
        ref.invalidate(dashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, l10n.operationFailed(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}