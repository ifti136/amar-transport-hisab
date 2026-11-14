import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';

/// A single label/value pair inside [VehicleSummaryCard].
class VehicleSummaryMetric {
  final String label;
  final String value;
  final Color? valueColor;

  const VehicleSummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

/// Presentational vehicle card shared by the Vehicles list and the dashboard.
///
/// It never watches providers; callers pass the expiry map and metrics.
/// Content is vertically stacked and grows with its content so it cannot
/// overflow on 360x640 screens or with large font scales.
class VehicleSummaryCard extends StatelessWidget {
  final String regNo;
  final String type;
  final IconData icon;
  final List<VehicleSummaryMetric> metrics;
  final Map<String, int?> expiry;
  final VoidCallback? onTap;

  const VehicleSummaryCard({
    super.key,
    required this.regNo,
    required this.type,
    required this.icon,
    required this.metrics,
    this.expiry = const {},
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon on the left, compact expiry badges on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 32),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: VehicleExpiryBadges(expiry: expiry),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Vehicle number is centred and may take two lines before it is
              // ellipsised; the type sits directly underneath.
              Text(
                regNo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (metrics.isNotEmpty) const SizedBox(height: 16),
              for (var i = 0; i < metrics.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _MetricBlock(metric: metrics[i])),
                    if (i + 1 < metrics.length) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _MetricBlock(metric: metrics[i + 1])),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final VehicleSummaryMetric metric;

  const _MetricBlock({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: metric.valueColor,
          ),
        ),
      ],
    );
  }
}

/// Compact insurance/fitness/tax badges used on vehicle cards.
class VehicleExpiryBadges extends StatelessWidget {
  final Map<String, int?> expiry;

  const VehicleExpiryBadges({super.key, required this.expiry});

  static const _order = ['insurance', 'fitness', 'tax'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>();
    final badges = <Widget>[];

    for (final key in _order) {
      final days = expiry[key];
      if (days == null) continue;

      final String label;
      final Color color;
      if (days <= 7) {
        color = semantic?.danger ?? AppColors.danger;
        label = key == 'insurance'
            ? l10n.expiryInsuranceShort
            : key == 'fitness'
                ? l10n.expiryFitnessShort
                : l10n.expiryTaxShort;
      } else if (days <= 30) {
        color = semantic?.warning ?? AppColors.warning;
        label = key == 'insurance'
            ? l10n.expiryInsuranceShort
            : key == 'fitness'
                ? l10n.expiryFitnessShort
                : l10n.expiryTaxShort;
      } else {
        color = semantic?.success ?? AppColors.success;
        label = key == 'insurance'
            ? l10n.expiryInsuranceShort
            : key == 'fitness'
                ? l10n.expiryFitnessShort
                : l10n.expiryTaxShort;
      }

      final status = days <= 0
          ? l10n.expiryExpired
          : l10n.expiryDaysLeft(days);

      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            '$label · $status',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }
}
