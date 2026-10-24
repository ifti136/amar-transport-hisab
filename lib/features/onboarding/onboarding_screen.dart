import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_hisab/core/services/business_name_provider.dart';
import 'package:transport_hisab/core/widgets/app_toast.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existingName = ref.read(businessNameProvider);
    if (existingName.isNotEmpty) {
      _nameController.text = existingName;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    try {
      if (name.isNotEmpty) {
        await ref.read(businessNameProvider.notifier).setBusinessName(name);
      }
      await ref.read(onboardingCompletedStateProvider.notifier).setCompleted(true);

      if (mounted) {
        if (name.isNotEmpty) {
          AppToast.showSuccess(context, l10n.businessNameSaved);
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, l10n.operationFailed(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 5 slides: 4 intro slides + 1 setup name slide
    const totalPages = 5;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < totalPages - 1)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  totalPages - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(l10n.skip, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // Slide 0: Welcome
                  _OnboardingSlide(
                    iconWidget: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.png', // i18n-ignore
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: l10n.onboardingWelcomeTitle,
                    description: l10n.onboardingWelcomeDesc,
                  ),

                  // Slide 1: Bengali First
                  _OnboardingSlide(
                    iconData: Icons.language,
                    title: l10n.onboardingBengaliTitle,
                    description: l10n.onboardingBengaliDesc,
                  ),

                  // Slide 2: 100% Offline
                  _OnboardingSlide(
                    iconData: Icons.cloud_off,
                    title: l10n.onboardingOfflineTitle,
                    description: l10n.onboardingOfflineDesc,
                  ),

                  // Slide 3: Secure & Private
                  _OnboardingSlide(
                    iconData: Icons.security,
                    title: l10n.onboardingSecureTitle,
                    description: l10n.onboardingSecureDesc,
                  ),

                  // Slide 4: Personalize / Name
                  _NameSetupSlide(
                    controller: _nameController,
                    title: l10n.onboardingNameTitle,
                    description: l10n.onboardingNameDesc,
                    label: l10n.businessNameLabel,
                    hint: l10n.businessNameHint,
                  ),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                        child: Text(l10n.back),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_currentPage < totalPages - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentPage == totalPages - 1 ? l10n.getStarted : l10n.next),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? iconData;
  final String title;
  final String description;

  const _OnboardingSlide({
    this.iconWidget,
    this.iconData,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconWidget != null)
            iconWidget!
          else if (iconData != null)
            Icon(iconData, size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameSetupSlide extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String description;
  final String label;
  final String hint;

  const _NameSetupSlide({
    required this.controller,
    required this.title,
    required this.description,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business, size: 64, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextFormField(
                    controller: controller,
                    autofocus: false,
                    style: theme.textTheme.titleMedium,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
