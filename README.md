# Amar Transport Hisab (আমার ট্রান্সপোর্ট হিসাব) 🚚📊

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/badge/Release-v0.2.3-green.svg)](https://github.com/ifti136/amar-transport-hisab/releases/tag/v0.2.3)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://developer.android.com)

**Amar Transport Hisab** is an offline-first, privacy-respecting Android accounting app tailored specifically for transport and covered van fleet owners in Bangladesh. Built from the ground up to replace paper notebooks (*খাতা*), it guarantees 100% offline data storage, strict double-entry ledger arithmetic, native Bengali typography, and accurate per-vehicle Profit & Loss reporting.

---

## 🚀 What's New in v0.2.3 (ভার্সন ০.২.৩ ফার্স্ট-রান ওয়াকথ্রু ও কাস্টম টপ বার নাম)

- 🚀 **First-Run Interactive Walkthrough (প্রথমবার ব্যবহারে পরিচিতি ওয়াকথ্রু):** Automatically launches a 5-slide guided onboarding flow when the user opens the app for the very first time, introducing Bengali-first localization, 100% offline privacy, and accounting integrity.
- 🏷️ **Business / Fleet Owner Name Setup (ব্যবসা বা মালিকের নাম সেটআপ):** At the end of the initial walkthrough, users can configure their business or fleet name (e.g., *আল-মদিনা ট্রান্সপোর্ট* or *M/S Karim Transport*).
- 📱 **Dynamic Top Bar Branding (লাইভ টপ বার টাইটেল):** Displays the entered business name directly on the home screen top bar (AppBar) in place of the generic app name, with automatic fallback if not provided.
- ⚙️ **Persistent & Editable in Settings (সেটিংস থেকে পরিবর্তনযোগ্য):** Users can edit their business name at any time from Settings > Business Profile, with instant reactive updates across the app and full local SQLite persistence.
- 🚛 **Dynamic Vehicle Filtering in Reports (রিপোর্টে গাড়িভিত্তিক ফিল্টার):** Full vehicle dropdown selector across Trip Register, Expense Register, Fuel Register, and Vehicle P&L reports with instant filtered calculations and exports.
- 💳 **Vehicle Loan Editing (গাড়ির লোন এডিট সুবিধা):** Direct editing capability for existing vehicle loans from loan cards and details, complete with audit trail tracking and balance recalculation.
- 🔍 **Database Audit & Robust Form Lifecycles:** Carried over full database audit validations, centralized `AppToast` alerts, double-submission guards (`_isSaving`), Bengali numeral support, and cascading fuel-diesel deletions.

---

## 📜 Version History (ভার্সন ইতিহাস)

- **v0.2.3:** Automatic first-run walkthrough, business/owner name onboarding prompt, dynamic top bar branding, settings business name editor with SQLite backup persistence.
- **v0.2.2:** Full database call audit, centralized AppToast feedback system, duplicate click prevention (_isSaving), form dismissal & reset lifecycle, Bengali numeral parsing across all modal dialogs, and cascade soft-delete integrity.
- **v0.2.1:** Profit card UI fix, vehicle numbers in alerts, optional customers & custom names, explicit trip completion actions, BaseDao comparison & saving fixes, consolidated 3-in-1 expense section with "Save & Add Another", future date picker support up to 2100, and Settings walkthrough.
- **v0.2.0:** Trip distance tracking, dual trip/vehicle expense logging, customizable categories, streamlined fuel logging, report loading fixes, logo branding, and form anti-duplicate guards.
- **v0.1.0:** Persistent bottom navigation, dedicated settings screen, biometric/PIN app lock, document expiry warnings, financial reports suite with PDF/Excel export, reliable local backup/restore.
- **v0.0.1:** Initial stable scaffold, offline SQLite database, pure Dart accounting engine, and Bengali/English localization.

---

## 🌟 Key Features (প্রধান সুবিধাসমূহ)

- 🇧🇩 **Native Bengali-First Interface (বাংলা ইন্টারফেস):** Full localization in Bengali with English toggle, Bengali numerals, and South Asian lakh/crore grouping (`৳ ১২,৩৪,৫৬৭.৮৯`).
- 📴 **100% Offline-First (সম্পূর্ণ অফলাইন):** All trip data, fuel records, driver salaries, and ledgers are stored securely on the device using SQLite (Drift). No internet connection or cloud account required.
- 💰 **Precision Accounting (সঠিক হিসাব):** All monetary figures stored as 64-bit integer paisa (১ টাকা = ১০০ পয়সা) eliminating floating-point rounding errors. 
- 🚛 **Per-Van P&L (প্রতি গাড়ির লাভ-ক্ষতি):** Instant monthly and yearly Profit & Loss reports for every vehicle (Covered Van), distinguishing operational revenue from actual cash collected.
- ⛽ **Fuel & Mileage Register (জ্বালানি হিসাব):** Diesel consumption logging per trip or van, average mileage (km/L) and cost per kilometer analytics.
- 👥 **Driver Accounts & Advances (ড্রাইভার খাতা):** Automatic tracking of trip allowances, advances, salary disbursements, and unsettled driver dues.
- 📑 **Customer Invoicing & Dues (কাস্টমার বাকি খাতা):** Record advance payments, calculate remaining dues automatically, and view full customer payment history.
- 🏦 **Vehicle Loans & EMI (গাড়ির কিস্তি/ঋণ):** Accurate separation of loan principal from interest expenses; loan installments reduce debt without improperly inflating operating expenses.
- ⚠️ **Document Expiry Alerts (কাগজপত্রের মেয়াদ সতর্কতা):** Visual warnings for Insurance, Fitness certificate, Tax token, and Route permit expiration dates.
- 📑 **PDF & Excel Exports (রিপোর্ট তৈরি):** Generate professional statement PDFs with embedded Bengali fonts and export detailed transaction tables to Excel (`.xlsx`).
- 🔐 **Privacy & Security (নিরাপত্তা):** Biometric (Fingerprint/Face unlock) or PIN protection, complete audit trail for modifications, and encrypted local backup/restore.

---

## 🏗️ Architecture & Technology Stack

- **Framework:** Flutter (Android-focused)
- **State Management:** Riverpod 2.x (`flutter_riverpod`, `riverpod_annotation`)
- **Database & Persistence:** Drift (SQLite) with reactive queries, foreign key integrity, and migrations
- **Navigation:** GoRouter
- **Localization:** Flutter `AppLocalizations` (ARB files for Bengali and English)
- **Formatting:** Custom Bangladeshi financial formatters (Lakh/Crore grouping, Bengali digit parsing)
- **Security:** `local_auth` (Biometrics), `cryptography` (Encrypted backups)
- **Reporting:** `pdf`, `printing`, `excel`, and `fl_chart`

---

## 📲 Installation Guide (ইনস্টলেশন গাইড)

1. **Download APK:** Download `Amar-Transport-Hisab-v0.2.1.apk` from the [Latest Release](https://github.com/ifti136/amar-transport-hisab/releases).
2. **Transfer to Device:** Copy the file to your Android phone via USB cable, Telegram/WhatsApp document, Google Drive, or directly in your mobile browser.
3. **Allow Installation:** Tap the downloaded APK file. When prompted by Android to allow installing apps from this source ("Install unknown apps"), grant permission.
4. **Play Protect Prompt:** If Google Play Protect displays a message regarding an unknown developer, tap **"More details"** and select **"Install anyway"**.
5. **Launch:** Open **Amar Transport Hisab** and begin setting up your fleet!

---

## 🚀 First-Run Setup (শুরুর নির্দেশনা)

1. **Language:** Choose Bengali (default) or English in Settings.
2. **Opening Balances:** If migrating mid-business, enter opening cash, customer receivables, driver advances, and bank loan balances.
3. **Add Vehicles:** Register your covered vans (Registration Number, model, purchase date, insurance/fitness expiry dates).
4. **Add Drivers:** Register regular drivers and set monthly salaries or trip allowance rates.
5. **Create Initial Backup:** Go to `Settings (সেটিংস) → Backup & Restore (ব্যাকআপ ও রিস্টোর)` and create a safety backup.

---

## 💾 Backup & Restore (ব্যাকআপ ও রিস্টোর)

### 📤 How to Backup
1. Go to **Settings (সেটিংস) → Backup & Restore (ব্যাকআপ ও রিস্টোর)**.
2. Tap **"Create Backup" (ব্যাকআপ তৈরি করুন)**.
3. (Optional) Enter a passphrase to encrypt your backup file.
4. Save/Share the `.hisabbackup` file outside the phone (Google Drive, Email, or Computer).

### 📥 How to Restore
1. Install the app on your new or reset phone.
2. Go to **Settings (সেটিংস) → Backup & Restore (ব্যাকআপ ও রিস্টোর)**.
3. Select your `.hisabbackup` file and enter your encryption passphrase if set.
4. Confirm restore. The app will replace existing records and reload your complete accounting ledger.

---

## 🛠️ Development & Building from Source

### Prerequisites
- Flutter SDK `>=3.3.0`
- Android SDK (API 34 / Java 17)
- Dart SDK `>=3.3.0`

### Build Steps

```bash
# Clone the repository
git clone https://github.com/ifti136/amar-transport-hisab.git
cd amar-transport-hisab

# Install dependencies
flutter pub get

# Generate Drift database code and Freezed models
dart run build_runner build --delete-conflicting-outputs

# Generate localizations
flutter gen-l10n

# Run unit and integration tests
flutter test

# Run static analysis
flutter analyze

# Build release APK
flutter build apk --release
```

The compiled release APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.
Copyright (c) 2026 Iftekharul Islam (ifti136).
