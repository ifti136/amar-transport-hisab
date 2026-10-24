import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:transport_hisab/core/db/database.dart';

const String kBusinessNameKey = 'business_name';
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Initial values overridden synchronously at app start
final initialOnboardingCompletedProvider = Provider<bool>((ref) => false);
final initialBusinessNameProvider = Provider<String>((ref) => '');

/// Notifier for business / owner name displayed in the top bar
class BusinessNameNotifier extends StateNotifier<String> {
  final Ref _ref;

  BusinessNameNotifier(this._ref, String initialValue) : super(initialValue) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(kBusinessNameKey) ?? '';
    if (cached.isNotEmpty) {
      state = cached;
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final setting = await (db.select(db.appSettings)..where((t) => t.key.equals(kBusinessNameKey))).getSingleOrNull();
      if (setting != null && setting.value.isNotEmpty) {
        state = setting.value;
        await prefs.setString(kBusinessNameKey, setting.value);
      }
    } catch (_) {}
  }

  Future<void> setBusinessName(String name) async {
    final trimmed = name.trim();
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBusinessNameKey, trimmed);

    try {
      final db = _ref.read(databaseProvider);
      await db.into(db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: kBusinessNameKey,
          value: trimmed,
        ),
      );
    } catch (_) {}
  }
}

final businessNameProvider = StateNotifierProvider<BusinessNameNotifier, String>((ref) {
  final initial = ref.watch(initialBusinessNameProvider);
  return BusinessNameNotifier(ref, initial);
});

/// Notifier for walkthrough / onboarding completion
class OnboardingCompletedNotifier extends StateNotifier<bool> {
  OnboardingCompletedNotifier(bool initial) : super(initial) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kOnboardingCompletedKey) ?? false;
  }

  Future<void> setCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompletedKey, completed);
    state = completed;
  }
}

final onboardingCompletedStateProvider = StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final initial = ref.watch(initialOnboardingCompletedProvider);
  return OnboardingCompletedNotifier(initial);
});

