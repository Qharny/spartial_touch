# SpatialTouch ✋

> Control any Android app with mid-air hand gestures — no screen touching required.

SpatialTouch is an Android app built with Flutter that uses your front camera and Google's MediaPipe hand-tracking to detect air gestures in real time. Wave your hand to scroll TikTok, pause a video, skip a track, or trigger any action — all while your phone sits on a table.

---

## Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Gesture Library](#gesture-library)
- [App Profiles](#app-profiles)
- [Screens](#screens)
- [Permissions](#permissions)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Development Roadmap](#development-roadmap)
- [Privacy](#privacy)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Background gesture detection** — works while you use any other app
- **Per-app profiles** — different gesture mappings for TikTok, YouTube, Spotify, and more
- **Full customization** — map any gesture to any action, adjust sensitivity, set cooldown timers
- **Smart wake** — proximity + accelerometer pre-filter activates camera only when a hand is nearby
- **On-device ML** — all processing is local via MediaPipe; no camera data ever leaves your device
- **Floating overlay** — draggable indicator bubble shows service status and flashes on gesture recognition
- **Active hours** — schedule the service to run only during certain times of day
- **Calibration wizard** — one-time setup tailors detection to your environment and lighting
- **Battery-aware** — three performance modes (Performance / Balanced / Battery Saver)

---

## How It Works

```
Hand approaches phone
        │
        ▼
Proximity + accelerometer sensor (smart wake)
        │
        ▼
Front camera activates (CameraX, 8–30 fps)
        │
        ▼
MediaPipe Hand Tracking → 21 hand landmarks
        │
        ▼
Gesture Interpreter → named gesture event
        │
        ▼
Confidence check + cooldown gate
        │
        ▼
Profile Matcher → which app is in foreground?
        │
        ▼
Action Dispatcher → gesture-to-action lookup
        │
        ▼
Android Accessibility Service → inject touch event
        │
        ▼
Overlay flashes + optional haptic feedback
```

---

## Architecture

SpatialTouch is split into two halves that communicate over a Flutter `MethodChannel`:

| Half | Description |
|---|---|
| **Flutter UI (Dart)** | All screens — dashboard, profiles, settings, onboarding, gesture tester, floating overlay |
| **Android Engine (Kotlin)** | Foreground Service, CameraX pipeline, MediaPipe inference, Accessibility Service injection |

### Layers

```
┌──────────────────────────────────────────────────────┐
│                    UI Layer (Flutter)                │
│   Dashboard · Profiles · Settings · Onboarding      │
├──────────────────────────────────────────────────────┤
│              MethodChannel Bridge (Dart ↔ Kotlin)    │
├──────────────────────────────────────────────────────┤
│          Service Layer (Android Foreground Service)  │
├──────────────────────────────────────────────────────┤
│       ML Layer (CameraX + MediaPipe Hand Tracking)   │
├──────────────────────────────────────────────────────┤
│    Gesture Layer (Interpreter + Confidence/Cooldown) │
├──────────────────────────────────────────────────────┤
│        Action Layer (Dispatcher + Profile Matcher)   │
├──────────────────────────────────────────────────────┤
│  System Layer (Accessibility API · Media · Global)   │
├──────────────────────────────────────────────────────┤
│         Storage Layer (SQLite · SharedPreferences)   │
└──────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) |
| State Management | Riverpod / BLoC |
| Hand Tracking | MediaPipe Hands (Flutter plugin) |
| Camera | CameraX (via Flutter plugin) |
| Background Service | Android Foreground Service (Kotlin) |
| Touch Injection | Android AccessibilityService |
| Local Database | sqflite (SQLite) |
| Preferences | shared_preferences |
| Notifications | flutter_local_notifications |
| Native Bridge | Flutter MethodChannel |
| Minimum SDK | Android 8.0 (API 26) |
| Target SDK | Android 14 (API 34) |

---

## Gesture Library

| Gesture | Motion | Default Action |
|---|---|---|
| Wave Up | Hand moves upward | Scroll up |
| Wave Down | Hand moves downward | Scroll down |
| Wave Left | Hand sweeps left | Swipe left |
| Wave Right | Hand sweeps right | Swipe right |
| Open Palm Hold | Flat palm held 1–2s | Play / Pause |
| Thumbs Up | Thumb extended up | Like / Upvote |
| Thumbs Down | Thumb extended down | Dislike |
| Index Point Up | Index finger extended up | Scroll to top |
| Pinch | Thumb + index close together | Zoom in |
| Two-Finger Swipe Right | Index + middle sweep right | Go forward |
| Two-Finger Swipe Left | Index + middle sweep left | Go back |
| Fist Pump | Closed fist toward camera | Screenshot |
| Rock Sign | Index + pinky extended | Custom shortcut |

### Configurable parameters per gesture

| Parameter | Default | Range |
|---|---|---|
| Confidence threshold | 0.75 | 0.50 – 0.95 |
| Cooldown timer | 800 ms | 300 – 2000 ms |
| Hold duration | 1.2 s | 0.5 – 3.0 s |
| Detection FPS | 15 | 5 – 30 |
| Motion threshold | 40 px | 20 – 100 px |

---

## App Profiles

Each profile links a specific installed app to its own gesture-to-action mapping. SpatialTouch auto-switches profiles when you switch apps.

### Built-in starter profiles

| App | Wave Up | Wave Down | Wave Left | Wave Right | Open Palm |
|---|---|---|---|---|---|
| TikTok | Next video | Prev video | Following feed | For You feed | Pause/Play |
| YouTube | Scroll up | Scroll down | Skip −10s | Skip +10s | Pause/Play |
| Instagram | Next reel | Prev reel | Go back | Like post | Pause/Play |
| Spotify | Volume up | Volume down | Prev track | Next track | Pause/Play |
| Maps | Zoom in | Zoom out | Pan left | Pan right | Centre map |
| **Default** | Scroll up | Scroll down | Swipe left | Swipe right | Pause/Play |

You can create unlimited custom profiles for any installed app.

---

## Screens

| Screen | Purpose |
|---|---|
| Splash | Launch screen, routes to onboarding or home |
| Onboarding (5 steps) | Permissions walkthrough + calibration |
| Dashboard | Main toggle, service status, quick stats |
| Profiles List | Browse, enable/disable, create profiles |
| Profile Editor | App picker + gesture-to-action mapping grid |
| Gesture Library | Enable/disable gestures, view animated previews |
| Gesture Detail | Per-gesture sensitivity, cooldown, live test |
| Settings | Overlay, haptics, active hours, performance mode |
| Gesture Tester | Live camera sandbox with landmark overlay |

---

## Permissions

| Permission | Why it's needed |
|---|---|
| `CAMERA` | Front camera for hand gesture detection |
| `FOREGROUND_SERVICE` | Keep gesture engine running in background |
| `FOREGROUND_SERVICE_CAMERA` | Android 14+ background camera requirement |
| `SYSTEM_ALERT_WINDOW` | Draw floating indicator over other apps |
| `AccessibilityService` | Inject scroll/tap/swipe into foreground apps |
| `RECEIVE_BOOT_COMPLETED` | Optional auto-start on device boot |
| `VIBRATE` | Haptic feedback on gesture recognition |

All camera processing is on-device. No frames are saved or transmitted.

---

## Getting Started

### Prerequisites

- Flutter 3.x
- Android Studio / VS Code with Flutter plugin
- Android device or emulator running API 26+
- Java 17

### Installation

```bash
# Clone the repo
git clone https://github.com/your-username/spatialtouch.git
cd spatialtouch

# Install dependencies
flutter pub get

# Run on a connected Android device
flutter run
```

> **Note:** The gesture engine requires a real Android device with a front camera. The emulator does not support CameraX input for MediaPipe inference.

### First launch

1. Grant **Camera** permission when prompted
2. Navigate to **Accessibility Settings** and enable SpatialTouch
3. Grant **Draw over other apps** permission (optional, for overlay)
4. Complete the **calibration wizard** — hold your hand at a natural distance from the camera
5. Create your first app profile or use the Default Profile

---

## Project Structure

```
spatialtouch/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── features/
│   │   ├── dashboard/
│   │   ├── onboarding/
│   │   ├── profiles/
│   │   ├── gestures/
│   │   ├── settings/
│   │   └── tester/
│   ├── core/
│   │   ├── bridge/          # MethodChannel communication
│   │   ├── database/        # SQLite + SharedPreferences
│   │   ├── models/          # Profile, GestureMap, Action
│   │   └── services/        # Local notification, overlay
│   └── shared/
│       ├── widgets/
│       └── theme/
├── android/
│   └── app/src/main/kotlin/
│       ├── MainActivity.kt
│       ├── GestureService.kt       # Foreground Service
│       ├── AccessibilityHandler.kt # Touch injection
│       ├── CameraEngine.kt         # CameraX pipeline
│       └── GestureInterpreter.kt   # MediaPipe → gesture
├── assets/
│   ├── animations/          # Lottie gesture previews
│   └── images/
├── test/
└── pubspec.yaml
```

---

## Development Roadmap

| Phase | Status | Description |
|---|---|---|
| v0.1 — Foundation | 🔲 | Foreground service + Accessibility Service scaffolding |
| v0.2 — Vision Core | 🔲 | MediaPipe integration, wave up/down detection |
| v0.3 — Background Engine | 🔲 | Camera in background, smart wake, overlay |
| v0.4 — Full Customization | 🔲 | Complete gesture + action library, profile system |
| v0.5 — Polish & UX | 🔲 | Onboarding, calibration, active hours, battery modes |
| v1.0 — Release | 🔲 | Play Store submission, demo video, portfolio docs |

---

## Privacy

- **Zero data transmission** — camera frames are processed in-memory and never saved to disk or sent to any server
- **No analytics** — no crash reporting, no usage tracking
- **No account required** — works fully offline
- **Foreground notification always visible** when camera is active
- Full privacy policy available at: `[your-privacy-policy-url]`

---

## Contributing

This is a personal portfolio project. Contributions, suggestions, and issue reports are welcome.

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Commit your changes
git commit -m "feat: your change description"

# Push and open a pull request
git push origin feature/your-feature-name
```

Please follow the existing code style and write tests for new features.

---

## License

```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

<p align="center">Built with Flutter · Powered by MediaPipe · Made for Android</p>