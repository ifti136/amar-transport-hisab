import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'money.dart';
export 'money.dart';

/// Bengali digits: ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯
const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
const _enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/// Converts Latin digits to Bengali digits.
String toBnDigits(String input) {
  return input.replaceAllMapped(RegExp(r'[0-9]'), (m) => _bnDigits[int.parse(m.group(0)!)]);
}

/// Converts Bengali digits to Latin digits.
String toEnDigits(String input) {
  return input.replaceAllMapped(RegExp(r'[০-৯]'), (m) => _enDigits[_bnDigits.indexOf(m.group(0)!)]);
}

/// Checks if the current locale is Bengali.
bool _isBnLocale(BuildContext? context) {
  if (context == null) return false;
  final locale = Localizations.maybeLocaleOf(context);
  return locale?.languageCode == 'bn';
}

/// Formats a number with lakh/crore grouping (Indian numbering system).
/// [decimals] - number of decimal places (null = no decimals)
String _formatGrouped(num value, {int? decimals, required bool isBn}) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();

  // Split integer and fractional parts
  final intPart = absValue.floor();
  final fracPart = decimals != null ? (absValue - intPart).toStringAsFixed(decimals).substring(2) : '';

  // Indian grouping: 1,00,000 (lakh), 1,00,00,000 (crore)
  String groupedInt;
  final intStr = intPart.toString();
  if (intStr.length <= 3) {
    groupedInt = intStr;
  } else if (intStr.length <= 5) {
    // Lakh: 12,345
    groupedInt = '${intStr.substring(0, intStr.length - 3)},${intStr.substring(intStr.length - 3)}';
  } else if (intStr.length <= 7) {
    // Lakh: 1,23,456
    groupedInt = '${intStr.substring(0, intStr.length - 5)},${intStr.substring(intStr.length - 5, intStr.length - 3)},${intStr.substring(intStr.length - 3)}';
  } else {
    // Crore: 1,23,45,678
    groupedInt = '${intStr.substring(0, intStr.length - 7)},${intStr.substring(intStr.length - 7, intStr.length - 5)},${intStr.substring(intStr.length - 5, intStr.length - 3)},${intStr.substring(intStr.length - 3)}';
  }

  final result = '$sign$groupedInt${fracPart.isNotEmpty ? '.$fracPart' : ''}';
  return isBn ? toBnDigits(result) : result;
}

/// Formats a [Money] value as BDT with lakh/crore grouping.
///
/// In Bengali UI: `১২,৩৪,৫৬৭ ৳` (symbol after, Bengali digits)
/// In English UI: `৳12,34,567` (symbol before, Latin digits)
///
/// [symbol] - whether to include the ৳ symbol (default: true)
/// [context] - used to determine locale (Bengali vs English)
String formatMoney(Money m, {bool symbol = true, BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final formatted = _formatGrouped(m.taka, decimals: m.paisa % 100 == 0 ? null : 2, isBn: isBn);

  if (!symbol) return formatted;

  if (isBn) {
    return '$formatted ৳'; // Bengali: symbol after
  } else {
    return '৳$formatted'; // English: symbol before
  }
}

/// Formats a plain number with lakh/crore grouping (no currency symbol).
String formatNumber(num n, {int? decimals, BuildContext? context}) {
  final isBn = _isBnLocale(context);
  return _formatGrouped(n, decimals: decimals, isBn: isBn);
}

/// Formats litres with 1 decimal place and unit.
String formatLitres(double litres, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final formatted = _formatGrouped(litres, decimals: 1, isBn: isBn);
  return isBn ? '$formatted লি' : '$formatted L';
}

/// Formats kilometres with grouping and unit.
String formatKm(int km, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final formatted = _formatGrouped(km, isBn: isBn);
  return isBn ? '$formatted কিমি' : '$formatted km';
}

/// Formats percentage with 1 decimal place.
String formatPercent(double p, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final formatted = _formatGrouped(p, decimals: 1, isBn: isBn);
  return '$formatted%';
}

/// Formats a date in the current locale.
///
/// Bengali: `২২ অক্টোবর ২০২৬` (full) / `২২ অক্টো` (short)
/// English: `22 Oct 2026` (full) / `22 Oct` (short)
String formatDate(DateTime d, {bool short = false, BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final locale = isBn ? 'bn' : 'en';

  if (short) {
    final fmt = DateFormat(isBn ? 'd MMM' : 'd MMM', locale);
    return isBn ? toBnDigits(fmt.format(d)) : fmt.format(d);
  }

  final fmt = DateFormat(isBn ? 'd MMMM yyyy' : 'd MMM yyyy', locale);
  return isBn ? toBnDigits(fmt.format(d)) : fmt.format(d);
}

/// Formats a month-year.
///
/// Bengali: `অক্টোবর ২০২৬`
/// English: `Oct 2026`
String formatMonth(DateTime d, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final locale = isBn ? 'bn' : 'en';
  final fmt = DateFormat(isBn ? 'MMMM yyyy' : 'MMM yyyy', locale);
  return isBn ? toBnDigits(fmt.format(d)) : fmt.format(d);
}

/// Formats a date range.
///
/// Bengali: `২২ অক্টোবর – ২৮ অক্টোবর ২০২৬`
/// English: `22–28 Oct 2026`
String formatDateRange(DateTime start, DateTime end, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final locale = isBn ? 'bn' : 'en';

  if (start.year == end.year && start.month == end.month) {
    // Same month: "22–28 Oct 2026"
    final dayFmt = DateFormat('d', locale);
    final monthFmt = DateFormat(isBn ? 'MMMM yyyy' : 'MMM yyyy', locale);
    final startDay = dayFmt.format(start);
    final endDay = dayFmt.format(end);
    final monthYear = monthFmt.format(start);
    final range = isBn ? '$startDay – $endDay $monthYear' : '$startDay–$endDay $monthYear';
    return isBn ? toBnDigits(range) : range;
  } else {
    // Different months: "22 Oct – 28 Nov 2026"
    final fmt = DateFormat(isBn ? 'd MMMM' : 'd MMM', locale);
    final startStr = fmt.format(start);
    final endStr = fmt.format(end);
    final yearStr = DateFormat('yyyy', locale).format(end);
    final range = isBn ? '$startStr – $endStr $yearStr' : '$startStr – $endStr $yearStr';
    return isBn ? toBnDigits(range) : range;
  }
}

/// Parses a money input string (accepts Bengali AND Latin digits, commas, decimal point).
/// Returns [Money] in paisa or a validation error string.
Result<Money, String> parseMoneyInput(String input) {
  // Normalize: Bengali digits → Latin, remove commas and spaces
  String normalized = toEnDigits(input.trim().replaceAll(',', '').replaceAll(' ', ''));

  if (normalized.isEmpty) {
    return const Failure('Amount is required');
  }

  if (normalized.startsWith('-')) {
    return const Failure('Amount cannot be negative');
  }

  // Check decimal places
  final firstDot = normalized.indexOf('.');
  final lastDot = normalized.lastIndexOf('.');
  if (firstDot != -1) {
    if (firstDot != lastDot) {
      return const Failure('Enter a valid number (max 2 decimals)');
    }
    final frac = normalized.substring(firstDot + 1);
    if (!RegExp(r'^\d+$').hasMatch(frac)) {
      return const Failure('Enter a valid number (max 2 decimals)');
    }
    if (frac.length > 2) {
      return const Failure('Maximum 2 decimal places');
    }
  }

  // Check for valid number format
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
    return const Failure('Enter a valid number (max 2 decimals)');
  }

  final value = double.tryParse(normalized);
  if (value == null) {
    return const Failure('Enter a valid number (max 2 decimals)');
  }

  return Success(Money.fromTaka(value));
}

/// Formats a [Money] for display in a TextField (with symbol, for input fields).
String formatMoneyForInput(Money m, {BuildContext? context}) {
  final isBn = _isBnLocale(context);
  final formatted = _formatGrouped(m.taka, decimals: m.paisa % 100 == 0 ? null : 2, isBn: isBn);
  return isBn ? '$formatted ৳' : '৳$formatted';
}