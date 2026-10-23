import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExpiryAlertsReport extends ConsumerWidget {
  const ExpiryAlertsReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportExpiryAlerts)),
      body: Center(child: Text('Expiry Alerts Report - TODO')),
    );
  }
}