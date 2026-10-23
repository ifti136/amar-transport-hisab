import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAppLockKey = 'app_lock_enabled';

/// App Lock Service for biometric / device PIN authentication
class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String localizedReason = 'Please authenticate to unlock Amar Transport Hisab'}) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) return true; // Fallback if device has no biometric or lock configured
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

/// Whether the app lock toggle is enabled in settings
class AppLockEnabledNotifier extends StateNotifier<bool> {
  AppLockEnabledNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kAppLockKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockKey, enabled);
    state = enabled;
  }
}

final appLockEnabledProvider = StateNotifierProvider<AppLockEnabledNotifier, bool>((ref) {
  return AppLockEnabledNotifier();
});

/// State whether the app is currently unlocked in this app lifecycle session
final appUnlockedProvider = StateProvider<bool>((ref) {
  // If app lock is not enabled, default to unlocked
  final isLockEnabled = ref.watch(appLockEnabledProvider);
  return !isLockEnabled;
});

