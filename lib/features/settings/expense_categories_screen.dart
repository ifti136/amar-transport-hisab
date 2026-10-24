import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:transport_hisab/features/money/expense_categories_provider.dart';

class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripCategories = ref.watch(tripCategoriesProvider);
    final vehicleCategories = ref.watch(vehicleCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseCategoriesTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CategorySection(
            title: l10n.tripExpenseOption,
            categories: tripCategories,
            isTrip: true,
            defaults: kDefaultTripCategories,
          ),
          const SizedBox(height: 24),
          _CategorySection(
            title: l10n.generalExpenseOption,
            categories: vehicleCategories,
            isTrip: false,
            defaults: kDefaultVehicleCategories,
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String title;
  final List<String> categories;
  final bool isTrip;
  final List<String> defaults;

  const _CategorySection({
    required this.title,
    required this.categories,
    required this.isTrip,
    required this.defaults,
  });

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.addCategoryTitle} ($title)'), // i18n-ignore
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.categoryNameLabel,
            hintText: l10n.categoryNameLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                if (isTrip) {
                  ref.read(tripCategoriesProvider.notifier).addCategory(text);
                } else {
                  ref.read(vehicleCategoriesProvider.notifier).addCategory(text);
                }
              }
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isTrip ? Icons.local_shipping : Icons.directions_bus, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.add),
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isDefault = defaults.contains(cat);
                final displayName = getCategoryDisplayName(cat, context);

                if (isDefault) {
                  return Chip(
                    label: Text(displayName),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  );
                }

                return InputChip(
                  label: Text(displayName),
                  onDeleted: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.delete),
                        content: Text(l10n.deleteCategoryConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                          FilledButton(
                            onPressed: () {
                              if (isTrip) {
                                ref.read(tripCategoriesProvider.notifier).removeCategory(cat);
                              } else {
                                ref.read(vehicleCategoriesProvider.notifier).removeCategory(cat);
                              }
                              Navigator.pop(ctx);
                            },
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                  },
                  backgroundColor: theme.colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

