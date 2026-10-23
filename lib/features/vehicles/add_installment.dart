import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loan_provider.dart';

class AddInstallmentSheet extends ConsumerStatefulWidget {
  final VehicleLoan loan;
  final Vehicle vehicle;

  const AddInstallmentSheet({super.key, required this.loan, required this.vehicle});

  @override
  ConsumerState<AddInstallmentSheet> createState() => _AddInstallmentSheetState();
}

class _AddInstallmentSheetState extends ConsumerState<AddInstallmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalPaidController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _installmentDate = DateTime.now();
  int _outstanding = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOutstanding();
  }

  Future<void> _loadOutstanding() async {
    final dao = ref.read(vehicleLoanDaoProvider);
    final outstanding = await dao.getLoanOutstanding(widget.loan.id, DateTime.now());
    if (mounted) {
      setState(() {
        _outstanding = outstanding;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _totalPaidController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updatePrincipal() {
    final total = double.tryParse(_totalPaidController.text) ?? 0;
    final interest = double.tryParse(_interestController.text) ?? 0;
    final principal = total - interest;
    if (principal >= 0) {
      _principalController.text = principal.toStringAsFixed(2);
    }
  }

  void _updateInterest() {
    final total = double.tryParse(_totalPaidController.text) ?? 0;
    final principal = double.tryParse(_principalController.text) ?? 0;
    final interest = total - principal;
    if (interest >= 0) {
      _interestController.text = interest.toStringAsFixed(2);
    }
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
            Text(l10n.addInstallmentTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Loan Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.loanDetailTitle(widget.loan.id)} - ${widget.vehicle.regNo}', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Principal', value: formatMoney(Money.paisa(widget.loan.principalPaisa), context: context)),
                    _SummaryRow(label: 'Interest Rate', value: '${(widget.loan.annualInterestRateBps / 100).toStringAsFixed(2)}%'),
                    _SummaryRow(label: 'Outstanding', value: formatMoney(Money.paisa(_outstanding), context: context), color: Theme.of(context).extension<AppSemanticColors>()!.danger),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _installmentDate,
                    firstDate: widget.loan.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _installmentDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.installmentDateLabel,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(formatDate(_installmentDate, context: context)),
                ),
              ),
              const SizedBox(height: 16),

              // Total Paid
              TextFormField(
                controller: _totalPaidController,
                decoration: InputDecoration(
                  labelText: l10n.totalPaidLabel,
                  hintText: l10n.totalPaidHint,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updatePrincipal(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return l10n.errorInvalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Principal Portion
              TextFormField(
                controller: _principalController,
                decoration: InputDecoration(
                  labelText: l10n.principalPortionLabel,
                  hintText: l10n.principalPortionHint,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateInterest(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) return l10n.errorInvalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest Portion
              TextFormField(
                controller: _interestController,
                decoration: InputDecoration(
                  labelText: l10n.interestPortionLabel,
                  hintText: l10n.interestPortionHint,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _updateInterest(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.errorRequired;
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) return l10n.errorInvalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Validation Warning
              _ValidationWarning(
                totalPaid: double.tryParse(_totalPaidController.text) ?? 0,
                principal: double.tryParse(_principalController.text) ?? 0,
                interest: double.tryParse(_interestController.text) ?? 0,
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.noteLabel,
                  hintText: 'Installment details',
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
                      child: Text(l10n.addInstallmentTitle),
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

    final totalPaid = (double.parse(_totalPaidController.text) * 100).round();
    final principal = (double.parse(_principalController.text) * 100).round();
    final interest = (double.parse(_interestController.text) * 100).round();

    // Validate principal + interest = total
    if (principal + interest != totalPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Principal + Interest must equal Total Paid')),
      );
      return;
    }

    // Validate principal <= outstanding
    if (principal > _outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.principalExceedsOutstanding)),
      );
      return;
    }

    final dao = ref.read(loanInstallmentDaoProvider);
    await dao.insertWithAudit(LoanInstallmentsCompanion.insert(
      loanId: widget.loan.id,
      installmentDate: _installmentDate,
      totalPaidPaisa: totalPaid,
      principalPortionPaisa: principal,
      interestPortionPaisa: interest,
      note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
    ), userNote: 'Loan installment added');

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(loanInstallmentsProvider(widget.loan.id));
      ref.invalidate(vehicleLoansProvider(widget.vehicle.id));
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ValidationWarning extends StatelessWidget {
  final double totalPaid;
  final double principal;
  final double interest;

  const _ValidationWarning({required this.totalPaid, required this.principal, required this.interest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sum = principal + interest;
    final hasError = (sum - totalPaid).abs() > 0.01;

    if (!hasError) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Principal + Interest (৳${sum.toStringAsFixed(2)}) ≠ Total Paid (৳${totalPaid.toStringAsFixed(2)})',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}