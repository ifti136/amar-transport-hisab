import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/business_name_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool(kOnboardingCompletedKey) ?? false;
  final businessName = prefs.getString(kBusinessNameKey) ?? '';

  runApp(
    ProviderScope(
      overrides: [
        initialOnboardingCompletedProvider.overrideWithValue(onboardingCompleted),
        initialBusinessNameProvider.overrideWithValue(businessName),
      ],
      child: const AmarTransportHisabApp(),
    ),
  );
}
