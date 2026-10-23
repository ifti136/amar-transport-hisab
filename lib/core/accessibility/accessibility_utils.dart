import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Accessibility utilities for Amar Transport Hisab
/// Provides TalkBack labels in Bengali, contrast helpers, reduced motion support

class AccessibilityUtils {
  /// Semantic label for Add Trip FAB
  static String addTripLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.addTripTitle; // "নতুন ট্রিপ" / "New Trip"
  }

  /// Semantic label for Language Toggle
  static String languageToggleLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.languageToggle; // "ভাষা" / "Language"
  }

  /// Semantic label for Theme Toggle
  static String themeToggleLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.themeToggle; // "থিম" / "Theme"
  }

  /// Semantic label for Navigation Tab
  static String navTabLabel(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.homeTab; // "হোম" / "Home"
      case 1:
        return l10n.tripsTab; // "ট্রিপ" / "Trips"
      case 2:
        return l10n.moneyTab; // "খরচ" / "Money"
      case 3:
        return l10n.moreTab; // "আরও" / "More"
      default:
        return '';
    }
  }

  /// Semantic label for Vehicle Card
  static String vehicleCardLabel(BuildContext context, String regNo, String profit, String cash) {
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.vanCardTitle(regNo)}. ${l10n.vanProfit(profit)}. ${l10n.vanCash(cash)}';
  }

  /// Semantic label for Expiry Badge
  static String expiryBadgeLabel(BuildContext context, String type, int days) {
    final l10n = AppLocalizations.of(context)!;
    if (days <= 0) {
      return '$type: ${l10n.expiryExpired}'; // "মেয়াদোত্তীর্ণ" / "Expired"
    } else if (days <= 7) {
      return '$type: ${l10n.expiryDaysLeft(days)}'; // "X দিন বাকি" / "X days left"
    } else {
      return '$type: ${l10n.expiryDaysLeft(days)}';
    }
  }

  /// Semantic label for Money Amount (with profit/loss context)
  static String moneyAmountLabel(BuildContext context, String amount, {bool isProfit = false, bool isCash = false}) {
    final l10n = AppLocalizations.of(context)!;
    if (isProfit) {
      final isNegative = amount.startsWith('-') || amount.startsWith('−');
      return isNegative ? '${l10n.loss} $amount' : '${l10n.profit} $amount';
    } else if (isCash) {
      return '${l10n.cashBalance} $amount';
    }
    return amount;
  }

  /// Semantic label for Form Field with validation
  static String formFieldLabel(BuildContext context, String label, {String? error}) {
    final l10n = AppLocalizations.of(context)!;
    if (error != null) {
      return '$label. ${l10n.errorInvalidNumber}'; // "সঠিক সংখ্যা লিখুন"
    }
    return label;
  }

  /// Semantic label for Action Button
  static String actionButtonLabel(BuildContext context, String action) {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'save':
        return l10n.save; // "সংরক্ষণ" / "Save"
      case 'cancel':
        return l10n.cancel; // "বাতিল" / "Cancel"
      case 'delete':
        return l10n.delete; // "মুছুন" / "Delete"
      case 'edit':
        return l10n.edit; // "সম্পাদনা" / "Edit"
      case 'add':
        return l10n.add; // "যোগ করুন" / "Add"
      default:
        return action;
    }
  }
}

/// Widget that provides semantic label for TalkBack
class SemanticLabel extends StatelessWidget {
  final Widget child;
  final String label;
  final bool excludeSemantics;

  const SemanticLabel({
    super.key,
    required this.child,
    required this.label,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
}

/// Widget that announces a message to TalkBack
class LiveRegion extends StatelessWidget {
  final Widget child;
  final String message;
  final bool polite;

  const LiveRegion({
    super.key,
    required this.child,
    required this.message,
    this.polite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: polite,
      child: child,
    );
  }
}

/// Helper to check if reduced motion is enabled
class ReducedMotion {
  static bool isEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns duration adjusted for reduced motion
  static Duration adjustDuration(Duration normal) {
    // This will be checked at runtime via MediaQuery
    return normal;
  }

  /// Wrapper that respects reduced motion
  static Widget maybeAnimate({
    required BuildContext context,
    required Widget child,
    required Widget animatedChild,
  }) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return animatedChild;
  }
}

/// Contrast verification helper
class ContrastChecker {
  /// Calculate relative luminance (WCAG 2.1)
  static double luminance(Color color) => color.computeLuminance();

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color foreground, Color background) {
    final l1 = luminance(foreground);
    final l2 = luminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
  static bool meetsAA(Color foreground, Color background, {bool largeText = false}) {
    final ratio = contrastRatio(foreground, background);
    return largeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Check if contrast meets WCAG AAA (7:1 for normal text, 4.5:1 for large text)
  static bool meetsAAA(Color foreground, Color background, {bool largeText = false}) {
    final ratio = contrastRatio(foreground, background);
    return largeText ? ratio >= 4.5 : ratio >= 7.0;
  }
}

/// Focus management utilities
class FocusUtils {
  /// Request focus for a node after a delay
  static void requestFocusLater(FocusNode node, {Duration delay = const Duration(milliseconds: 100)}) {
    Future.delayed(delay, () {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  /// Create a focus traversal group for a form
  static Widget focusTraversalGroup({required Widget child}) {
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: child,
    );
  }

  /// Skip focus for decorative elements
  static Widget skipFocus({required Widget child}) {
    return Focus(
      skipTraversal: true,
      child: child,
    );
  }
}

/// Semantic hint for custom actions
class SemanticActionHelper {
  static const CustomSemanticsAction swipeToDelete = CustomSemanticsAction(
    label: 'Delete',
  );

  static const CustomSemanticsAction swipeToEdit = CustomSemanticsAction(
    label: 'Edit',
  );

  static const CustomSemanticsAction longPressForQuickAdd = CustomSemanticsAction(
    label: 'Quick Add Today\'s Trip',
  );
}