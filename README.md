# GoalOS — AI-Powered Personal Life Execution System

> An offline-first Flutter Android app that transforms life goals into structured daily execution plans.

---

## 📱 App Overview

GoalOS is NOT a simple to-do app. It is a **personal operating system for life execution** that:

- Converts long-term life goals into daily structured tasks
- Generates AI-optimized hourly time blocks based on energy patterns
- Tracks habits with streak motivation
- Shows goal alignment scores and productivity metrics
- Works 100% offline — no backend, no cloud, no account needed
- Fully bilingual: **English + Arabic (العربية)** with RTL support

---

## 🚀 Build Instructions

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.19.x or later |
| Dart | 3.3.x or later |
| Android SDK | API 21+ (Android 5.0+) |
| Java JDK | 17 |

### Step 1: Create Flutter Project Base

```bash
flutter create goalos_base --platforms android --org com.goalos
cd goalos_base
```

### Step 2: Replace Source Files

Copy the entire contents of this folder into your `goalos_base/` directory, replacing existing files:
- Replace `pubspec.yaml`
- Replace `lib/` folder entirely
- Replace `android/` folder entirely
- Copy `assets/` folder
- Copy `l10n.yaml`

### Step 3: Set Up Android Local Properties

Edit `android/local.properties`:
```
sdk.dir=/Users/YOU/Library/Android/sdk        # macOS
sdk.dir=C:\\Users\\YOU\\AppData\\Local\\Android\\sdk  # Windows
flutter.sdk=/Users/YOU/flutter                 # path to Flutter SDK
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
flutter.minSdkVersion=21
flutter.targetSdkVersion=34
flutter.compileSdkVersion=34
```

### Step 4: Add Cairo Font Files

Download Cairo font from Google Fonts: https://fonts.google.com/specimen/Cairo

Place these files in `assets/fonts/`:
```
assets/fonts/Cairo-Regular.ttf
assets/fonts/Cairo-Bold.ttf
assets/fonts/Cairo-SemiBold.ttf
```

### Step 5: Install Dependencies

```bash
flutter pub get
```

### Step 6: Generate Localizations

```bash
flutter gen-l10n
```

This creates `lib/flutter_gen/gen_l10n/app_localizations.dart` (auto-generated, do not edit).

### Step 7: Build APK

**Debug APK** (for testing):
```bash
flutter build apk --debug
```

**Release APK** (single file):
```bash
flutter build apk --release
```

**Release APK** (split by ABI — smaller files, recommended):
```bash
flutter build apk --split-per-abi --release
```

Output location: `build/app/outputs/flutter-apk/`

---

## 📂 Project Structure

```
goalos/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Colors, typography, constants
│   │   └── localization/
│   │       ├── app_en.arb                 # English strings
│   │       └── app_ar.arb                 # Arabic strings
│   ├── data/
│   │   ├── models/
│   │   │   ├── goal_model.dart            # Goal Hive model
│   │   │   ├── task_model.dart            # Task Hive model
│   │   │   ├── habit_model.dart           # Habit Hive model
│   │   │   ├── time_block_model.dart      # Time block Hive model
│   │   │   └── hive_adapters.dart         # Manual Hive TypeAdapters
│   │   └── repositories/
│   │       └── scheduling_engine.dart     # AI scheduling engine (rule-based)
│   └── presentation/
│       ├── providers/
│       │   └── app_providers.dart         # All Riverpod state providers
│       ├── screens/
│       │   ├── main_shell.dart            # Bottom nav shell
│       │   ├── onboarding/                # 3-page welcome flow
│       │   ├── dashboard/                 # Daily execution view
│       │   ├── goals/                     # Goals CRUD + detail + AI decomposition
│       │   ├── tasks/                     # Task form
│       │   ├── habits/                    # Habit tracker with streaks
│       │   ├── schedule/                  # Calendar time-block view
│       │   ├── analytics/                 # Charts + productivity insights
│       │   └── settings/                  # Language switch + data reset
│       └── widgets/
│           ├── common/priority_badge.dart
│           └── dashboard/
│               ├── alignment_score_card.dart
│               └── time_block_card.dart
├── assets/
│   ├── fonts/                             # Cairo font files (add manually)
│   └── icons/                            
├── android/                               # Full Android project
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/goalos/app/MainActivity.kt
│   │       └── res/                       # Icons, styles, drawables
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── pubspec.yaml
└── l10n.yaml
```

---

## 🧠 AI Scheduling Engine

The scheduling engine (`scheduling_engine.dart`) implements:

### Priority Scoring Algorithm
```
score = priority_color_score (0-40)
      + goal_importance_score (0-30)  
      + deadline_urgency_score (0-30)
```

### Energy Zone Mapping
| Time | Zone | Task Type |
|------|------|-----------|
| 7:00–12:00 | Morning Peak | 🔴 Red (Deep Work) |
| 12:00–15:00 | Midday | 🟠 Orange (Learning/Medium) |
| 15:00–18:00 | Afternoon | 🟡 Yellow (Normal) |
| 18:00–22:00 | Evening | 🟢 Green (Habits/Light) |

### Auto-Optimization
- Reschedules missed high-priority tasks to next morning
- Protects red-priority tasks from being moved
- Moves gray tasks first when conflicts arise
- Goal-aligned blocks are protected

---

## 🌍 Bilingual Support

- All UI text uses Flutter's `AppLocalizations` system
- Language stored in `SharedPreferences` (persists across app restarts)
- Switching language instantly toggles full RTL/LTR layout via `Directionality`
- All data fields stored in both AR/EN: `title_en`, `title_ar`, `description_en`, `description_ar`
- Calendar and time blocks respect text direction

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Background | `#1A1A2E` |
| Secondary | `#16213E` |
| Surface | `#0F3460` |
| Accent/Highlight | `#E94560` |
| Text Primary | `#FFFFFF` |
| Text Muted | `#94A3B8` |
| Font | Cairo (Arabic-optimized) |

### Priority Color System
| Color | Meaning |
|-------|---------|
| 🔴 Red | High impact / Deep work |
| 🟠 Orange | Important tasks |
| 🟡 Yellow | Normal tasks |
| 🟢 Green | Habits / Health |
| ⚪ Gray | Optional / Low priority |

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `hive_flutter` | Offline local database |
| `google_fonts` | Cairo font |
| `flutter_animate` | Smooth animations |
| `percent_indicator` | Progress rings/bars |
| `table_calendar` | Schedule calendar view |
| `fl_chart` | Analytics pie chart |
| `gap` | Spacing utility |
| `flutter_slidable` | Swipe-to-delete |
| `intl` | Date formatting |
| `uuid` | Unique IDs for models |
| `shared_preferences` | Settings persistence |
| `collection` | List utilities |

---

## ✅ Feature Checklist

- [x] Goals system (bilingual CRUD with priority, deadline, progress)
- [x] Task system (color-coded priority, status tracking)
- [x] Habits tracker (streaks, completion rate, goal linking)
- [x] AI scheduling engine (rule-based priority scoring)
- [x] Daily time-block generation (energy-matched)
- [x] Dashboard (alignment score, top priorities, today's schedule)
- [x] Schedule screen (calendar + hourly blocks)
- [x] Analytics (productivity score, charts, goal predictions)
- [x] Settings (language EN/AR + RTL + data reset)
- [x] Onboarding (3-screen welcome flow)
- [x] Full offline operation (Hive database)
- [x] Arabic + English (all strings in ARB files)
- [x] RTL layout support
- [x] Dark theme

---

## 🔧 Troubleshooting

**`flutter gen-l10n` fails:**
Make sure `l10n.yaml` is in the project root and `pubspec.yaml` has `generate: true`.

**Hive adapter errors:**
Manual adapters are provided — do NOT run `build_runner` unless you remove the manual adapters first.

**Font not loading:**
Make sure Cairo `.ttf` files are in `assets/fonts/` and `pubspec.yaml` references them correctly.

**Build fails with Gradle error:**
Update `android/local.properties` with correct SDK and Flutter SDK paths.

---

*GoalOS — Every hour has a purpose. Every task links to your goals.*
