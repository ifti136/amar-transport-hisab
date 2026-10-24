import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';
import 'package:transport_hisab/features/dashboard/dashboard_provider.dart';
import 'package:transport_hisab/features/drivers/driver_account_provider.dart';

class PaySalarySheet extends ConsumerStatefulWidget {
  final Driver driver;

  const PaySalarySheet({super.key, required this.driver});

  @override
  ConsumerState<PaySalarySheet> createState() => _PaySalarySheetState();
}

class _PaySalarySheetState extends ConsumerState<PaySalarySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int _salaryEarned = 0;
  int _salaryPaid = 0;
  int _outstandingAdvance = 0;
  int _autoDeductAdvance = 0;
  bool _loading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final dao = ref.read(driverTransactionDaoProvider);
    final salaryEarned = await dao.getTotalSalaryEarned(widget.driver.id, endOfMonth);
    final salaryPaid = await dao.getTotalSalaryPaid(widget.driver.id, endOfMonth);
    final outstandingAdvance = await dao.getOutstandingAdvance(widget.driver.id, endOfMonth);

    if (mounted) {
      setState(() {
        _salaryEarned = salaryEarned;
        _salaryPaid = salaryPaid;
        _outstandingAdvance = outstandingAdvance;
        _autoDeductAdvance = outstandingAdvance > 0 ? outstandingAdvance : 0;
        _amountController.text = (_salaryEarned - _salaryPaid - _autoDeductAdvance).toString();
        _loading = false;
      });
    }
  }

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
            Text(l10n.paySalaryTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Salary Earned', value: formatMoney(Money.paisa(_salaryEarned), context: context)),
                      _SummaryRow(label: 'Salary Paid', value: formatMoney(Money.paisa(_salaryPaid), context: context)),
                      _SummaryRow(label: 'Outstanding Advance', value: formatMoney(Money.paisa(_outstandingAdvance), context: context), color: Theme.of(context).extension<AppSemanticColors>()!.warning),
                      const Divider(),
                      _SummaryRow(label: 'Net Payable', value: formatMoney(Money.paisa(_salaryEarned - _salaryPaid - _outstandingAdvance), context: context), isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

                // Advance Deduction
                Text(l10n.giveAdvanceTitle, style: theme.textTheme.titleMedium), // Reuse "Give Advance" as "Advance Deduction"
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _autoDeductAdvance > 0 ? (_autoDeductAdvance / 100).toStringAsFixed(2) : '0.00',
                        decoration: InputDecoration(
                          labelText: l10n.advanceDeductLabel,
                          prefixText: '৳ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final parsed = double.tryParse(value) ?? 0;
                          setState(() => _autoDeductAdvance = (parsed * 100).round());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.maxAdvanceLabel(formatMoney(Money.paisa(_outstandingAdvance), context: context))),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount to Pay
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amountLabel,
                    prefixText: '৳ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return l10n.errorInvalidNumber;
                    final maxPayable = _salaryEarned - _salaryPaid;
                    if (parsed > maxPayable) return l10n.errorRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteLabel,
                    hintText: 'Salary payment for ${DateTime.now().month}/${DateTime.now().year}', // i18n-ignore
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
                            : Text(l10n.paySalaryTitle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
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

    final advanceDeducted = _autoDeductAdvance;

    setState(() => _isSaving = true);

    try {
      final dao = ref.read(driverTransactionDaoProvider);

      // Create salary_paid transaction
      await dao.insertWithAudit(DriverTransactionsCompanion(
        driverId: Value(widget.driver.id),
        type: const Value('salary_paid'),
        amountPaisa: Value(amountPaisa),
        transactionDate: Value(DateTime.now()),
        note: Value(_noteController.text.trim().isEmpty ? 'Salary payment' : _noteController.text.trim()),
      ), userNote: 'Salary paid');

      // Create advance_deducted transaction if advance deducted
      if (advanceDeducted > 0) {
        await dao.insertWithAudit(DriverTransactionsCompanion(
          driverId: Value(widget.driver.id),
          type: const Value('advance_deducted'),
          amountPaisa: Value(advanceDeducted),
          transactionDate: Value(DateTime.now()),
          note: const Value('Advance deducted from salary'),
        ), userNote: 'Advance deducted from salary');
      }

      if (mounted) {
        AppToast.showSuccess(context, l10n.salaryPaidSuccess);
        Navigator.pop(context);
        ref.invalidate(driverTransactionsProvider(widget.driver.id));
        ref.invalidate(driverBalanceProvider(DriverBalanceFilter(driverId: widget.driver.id, upTo: DateTime.now())));
        ref.invalidate(outstandingAdvanceProvider(OutstandingAdvanceFilter(driverId: widget.driver.id, upTo: DateTime.now())));
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.color, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}