import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_hisab/core/db/database.dart';
import 'package:transport_hisab/features/vehicles/vehicle_provider.dart';

const String _kExpiryAlertsKey = 'expiry_alerts_enabled';

class ExpiryAlertsEnabledNotifier extends StateNotifier<bool> {
  ExpiryAlertsEnabledNotifier() : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kExpiryAlertsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kExpiryAlertsKey, enabled);
    state = enabled;
  }
}

final expiryAlertsEnabledProvider = StateNotifierProvider<ExpiryAlertsEnabledNotifier, bool>((ref) {
  return ExpiryAlertsEnabledNotifier();
});

class DocumentExpiryItem {
  final int vehicleId;
  final String regNo;
  final String documentType;
  final String expiryDate;
  final int daysRemaining;
  final bool isExpired;
  final bool isUrgent; // <= 7 days

  DocumentExpiryItem({
    required this.vehicleId,
    required this.regNo,
    required this.documentType,
    required this.expiryDate,
    required this.daysRemaining,
    required this.isExpired,
    required this.isUrgent,
  });
}

/// Provider calculating active document expiry alerts across all vehicles
final vehicleExpiryAlertsListProvider = Provider<List<DocumentExpiryItem>>((ref) {
  final isEnabled = ref.watch(expiryAlertsEnabledProvider);
  if (!isEnabled) return [];

  final vehiclesAsync = ref.watch(activeVehiclesProvider);
  return vehiclesAsync.maybeWhen(
    data: (vehicles) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final alerts = <DocumentExpiryItem>[];

      for (final v in vehicles) {
        _checkExpiry(v.id, v.regNo, 'Fitness', v.fitnessExpiry, today, alerts);
        _checkExpiry(v.id, v.regNo, 'Insurance', v.insuranceExpiry, today, alerts);
        _checkExpiry(v.id, v.regNo, 'Tax Token', v.taxExpiry, today, alerts);
      }

      alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
      return alerts;
    },
    orElse: () => [],
  );
});

void _checkExpiry(
  int vehicleId,
  String regNo,
  String docType,
  DateTime? date,
  DateTime today,
  List<DocumentExpiryItem> list,
) {
  if (date == null) return;
  final expiryDate = DateTime(date.year, date.month, date.day);
  final days = expiryDate.difference(today).inDays;

  if (days <= 30) {
    list.add(DocumentExpiryItem(
      vehicleId: vehicleId,
      regNo: regNo,
      documentType: docType,
      expiryDate: '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
      daysRemaining: days,
      isExpired: days < 0,
      isUrgent: days >= 0 && days <= 7,
    ));
  }
}

