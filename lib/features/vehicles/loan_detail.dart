import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/core/formatters.dart';
import 'package:transport_hisab/core/theme/colors.dart';
import 'package:transport_hisab/features/vehicles/vehicle_loan_provider.dart';
import 'package:transport_hisab/features/vehicles/add_installment.dart';
import 'package:transport_hisab/features/vehicles/add_loan.dart';

class LoanDetailScreen extends ConsumerWidget {
  final VehicleLoan loan;
  final Vehicle vehicle;

  const LoanDetailScreen({super.key, required this.loan, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final installmentsAsync = ref.watch(loanInstallmentsProvider(loan.id));
    final outstandingAsync = ref.watch(loanOutstandingProvider(LoanOutstandingFilter(loanId: loan.id, upTo: DateTime.now())));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loanDetailTitle(loan.id)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => AddLoanSheet(vehicle: vehicle, loan: loan),
              );
            },
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddInstallment(context),
            tooltip: l10n.addInstallmentTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          // Loan Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.loanDetailTitle(loan.id), style: theme.textTheme.headlineSmall),
                            Text('${l10n.vehicleLabel}: ${vehicle.regNo}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)), // i18n-ignore
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _SummaryItem(label: 'Principal', value: formatMoney(Money.paisa(loan.principalPaisa), context: context))),
                      Expanded(child: _SummaryItem(label: 'Interest Rate', value: '${(loan.annualInterestRateBps / 100).toStringAsFixed(2)}%')),
                      Expanded(child: _SummaryItem(label: 'Start Date', value: formatDate(loan.startDate, context: context))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _SummaryItem(label: 'Outstanding', value: outstandingAsync.when(
                        data: (v) => formatMoney(Money.paisa(v), context: context),
                        loading: () => '...',
                        error: (_, __) => 'Error',
                      ), color: theme.extension<AppSemanticColors>()!.danger)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Installments
          Expanded(
            child: installmentsAsync.when(
              data: (installments) {
                if (installments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(l10n.noInstallmentsYet, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(l10n.addFirstInstallment, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: installments.length,
                  itemBuilder: (context, index) {
                    final inst = installments[index];
                    return _InstallmentCard(installment: inst);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')), // i18n-ignore
            ),
          ),
        ],
      ),
    );
  }

  void _showAddInstallment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddInstallmentSheet(loan: loan, vehicle: vehicle),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  final LoanInstallment installment;

  const _InstallmentCard({required this.installment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: semantic.success.withValues(alpha: 0.1),
                  child: Icon(Icons.payments, color: semantic.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.installmentDetail(installment.id), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(formatDate(installment.installmentDate, context: context), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoItem(label: 'Total Paid', value: formatMoney(Money.paisa(installment.totalPaidPaisa), context: context))),
                Expanded(child: _InfoItem(label: 'Principal', value: formatMoney(Money.paisa(installment.principalPortionPaisa), context: context), color: semantic.success)),
                Expanded(child: _InfoItem(label: 'Interest', value: formatMoney(Money.paisa(installment.interestPortionPaisa), context: context), color: semantic.danger)),
              ],
            ),
            if (installment.note != null && installment.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.installmentNote(installment.note!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}