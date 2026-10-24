import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const List<String> kDefaultTripCategories = [
  'toll',
  'chanda',
  'police_tips',
  'labour',
  'parking',
  'weighbridge',
  'other',
];

const List<String> kDefaultVehicleCategories = [
  'maintenance',
  'repair',
  'tax_token',
  'fitness',
  'insurance',
  'route_permit',
  'servicing',
  'other',
];

class ExpenseCategoriesNotifier extends StateNotifier<List<String>> {
  final String _prefKey;
  final List<String> _defaults;

  ExpenseCategoriesNotifier(this._prefKey, this._defaults) : super(_defaults) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_prefKey);
    if (custom != null && custom.isNotEmpty) {
      final combined = {..._defaults, ...custom}.toList();
      state = combined;
    }
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    final updated = [...state, trimmed];
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    final customList = updated.where((c) => !_defaults.contains(c)).toList();
    await prefs.setStringList(_prefKey, customList);
  }

  Future<void> removeCategory(String category) async {
    if (_defaults.contains(category)) return; // Default categories protected
    final updated = state.where((c) => c != category).toList();
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    final customList = updated.where((c) => !_defaults.contains(c)).toList();
    await prefs.setStringList(_prefKey, customList);
  }
}

final tripCategoriesProvider = StateNotifierProvider<ExpenseCategoriesNotifier, List<String>>((ref) {
  return ExpenseCategoriesNotifier('custom_trip_categories', kDefaultTripCategories);
});

final vehicleCategoriesProvider = StateNotifierProvider<ExpenseCategoriesNotifier, List<String>>((ref) {
  return ExpenseCategoriesNotifier('custom_vehicle_categories', kDefaultVehicleCategories);
});

String getCategoryDisplayName(String cat, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final isBn = Localizations.maybeLocaleOf(context)?.languageCode == 'bn';

  switch (cat) {
    case 'toll':
      return isBn ? 'টোল (Toll)' : 'Toll'; // i18n-ignore
    case 'chanda':
      return isBn ? 'চাঁদা (Chanda)' : 'Chanda'; // i18n-ignore
    case 'police_tips':
      return isBn ? 'পুলিশ বখশিস (Police Tips)' : 'Police Tips'; // i18n-ignore
    case 'labour':
      return isBn ? 'লেবার / কুলি (Labour)' : 'Labour'; // i18n-ignore
    case 'parking':
      return isBn ? 'পার্কিং (Parking)' : 'Parking'; // i18n-ignore
    case 'weighbridge':
      return isBn ? 'ওয়েব্রিজ / স্কেল (Weighbridge)' : 'Weighbridge'; // i18n-ignore
    case 'maintenance':
      return isBn ? 'রক্ষণাবেক্ষণ (Maintenance)' : 'Maintenance'; // i18n-ignore
    case 'repair':
      return isBn ? 'মেরামত (Repair)' : 'Repair'; // i18n-ignore
    case 'tax_token':
      return isBn ? 'ট্যাক্স টোকেন (Tax Token)' : 'Tax Token'; // i18n-ignore
    case 'fitness':
      return isBn ? 'ফিটনেস (Fitness)' : 'Fitness'; // i18n-ignore
    case 'insurance':
      return isBn ? 'বীমা (Insurance)' : 'Insurance'; // i18n-ignore
    case 'route_permit':
      return isBn ? 'রুট পারমিট (Route Permit)' : 'Route Permit'; // i18n-ignore
    case 'servicing':
      return isBn ? 'সার্ভিসিং (Servicing)' : 'Servicing'; // i18n-ignore
    case 'diesel':
      return isBn ? 'ডিজেল (Diesel)' : 'Diesel'; // i18n-ignore
    case 'other':
      return isBn ? 'অন্যান্য (Other)' : 'Other'; // i18n-ignore
    default:
      return cat;
  }
}
