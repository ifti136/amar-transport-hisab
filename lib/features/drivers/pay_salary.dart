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
import 'package:transport_hisab/features/drivers/driver_provider.dart';
import 'package:transport_hisab/domain/accounting/driver_salary.dart';

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
  final _deductionController = TextEditingController();

  int _salaryEarned = 0;
  int _salaryPaid = 0;
  int _outstandingAdvance = 0;
  int _deductionPaisa = 0;
  bool _loading = true;
  bool _isSaving = false;

  SalaryPayable get _payable => SalaryPayable(
        earnedPaisa: _salaryEarned,
        paidPaisa: _salaryPaid,
        outstandingAdvancePaisa: _outstandingAdvance,
        deductionPaisa: _deductionPaisa,
      );

  String _takaInput(int paisa) {
    final taka = paisa / 100;
    return taka == taka.roundToDouble()
        ? taka.toStringAsFixed(0)
        : taka.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      await ref.read(salaryAccrualServiceProvider).ensureMonthlySalaryAccrued();
    } catch (_) {
      // Totals below still work if accrual fails.
    }

    final dao = ref.read(driverTransactionDaoProvider);
    final salaryEarned = await dao.getTotalSalaryEarned(widget.driver.id, endOfMonth);
    final salaryPaid = await dao.getTotalSalaryPaid(widget.driver.id, endOfMonth);
    final outstandingAdvance = await dao.getOutstandingAdvance(widget.driver.id, endOfMonth);

    if (mounted) {
      setState(() {
        _salaryEarned = salaryEarned;
        _salaryPaid = salaryPaid;
        _outstandingAdvance = outstandingAdvance;
        _deductionPaisa = outstandingAdvance > 0 ? outstandingAdvance : 0;
        final payable = _payable;
        _deductionPaisa = payable.clampedDeductionPaisa;
        _deductionController.text = _takaInput(_deductionPaisa);
        _amountController.text = _takaInput(payable.netPayablePaisa);
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                      _SummaryRow(label: l10n.salaryEarnedLabel, value: formatMoney(Money.paisa(_salaryEarned), context: context)),
                      _SummaryRow(label: l10n.salaryPaidLabel, value: formatMoney(Money.paisa(_salaryPaid), context: context)),
                      _SummaryRow(label: l10n.outstandingAdvanceShort, value: formatMoney(Money.paisa(_outstandingAdvance), context: context), color: Theme.of(context).extension<AppSemanticColors>()!.warning),
                      const Divider(),
                      _SummaryRow(label: l10n.netPayableLabel, value: formatMoney(Money.paisa(_payable.netPayablePaisa), context: context), isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

                // Advance Deduction
                Text(l10n.advanceDeductionLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('salary_deduction_field'),
                        controller: _deductionController,
                        decoration: InputDecoration(
                          labelText: l10n.advanceDeductLabel,
                          prefixText: '৳ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = parseMoneyInput(value);
                          if (parsed is Failure) return l10n.errorInvalidNumber;
                          return null;
                        },
                        onChanged: (value) {
                          final parsed = parseMoneyInput(value);
                          setState(() {
                            _deductionPaisa =
                                parsed is Success ? parsed.value.paisa : 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        l10n.maxDeductionHint(
                          formatMoney(Money.paisa(_payable.maxDeductionPaisa), context: context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount to Pay
                TextFormField(
                  key: const Key('salary_amount_field'),
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amountLabel,
                    prefixText: '৳ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                    final parsed = parseMoneyInput(value);
                    if (parsed is Failure) return l10n.errorInvalidNumber;
                    final paisa = parsed.value.paisa;
                    if (paisa <= 0) return l10n.errorPositiveAmount;
                    if (paisa > _payable.netPayablePaisa) {
                      return l10n.errorExceedsPayable;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteLabel,
                    hintText: l10n.noteHintSalary(DateTime.now().month, DateTime.now().year),
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
                        key: const Key('salary_save_button'),
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

    final advanceDeducted = _payable.clampedDeductionPaisa;

    setState(() => _isSaving = true);

    try {
      final dao = ref.read(driverTransactionDaoProvider);
      final db = ref.read(databaseProvider);

      await db.transaction(() async {
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
      });

      if (mounted) {
        AppToast.showSuccess(context, l10n.salaryPaidSuccess);
        Navigator.pop(context);
        ref.invalidate(driverTransactionsProvider(widget.driver.id));
        ref.invalidate(driverLedgerProvider);
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