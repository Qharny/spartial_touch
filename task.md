# SpatialTouch - Remaining Tasks

Based on the Development Roadmap in the project's README and the current state of the codebase, here are the detailed tasks left to be done:

## Phase 1: Foundation (v0.1)
- `[ ]` **Complete Android Foreground Service**: Fully implement the `GestureService.kt` to ensure it can run stably in the background and survive app suspension.
- `[ ]` **Accessibility Service Implementation**: Finalize `SpatialTouchAccessibilityService.kt` to allow injecting scroll/tap/swipe events reliably.
- `[ ]` **MethodChannel Bridge**: Solidify `gesture_channel.dart` to ensure stable bidirectional communication between Flutter and the Kotlin background service.

## Phase 2: Vision Core (v0.2)
- `[ ]` **MediaPipe Integration**: Fully wire up `HandTracker.kt` to extract 21 hand landmarks accurately using the CameraX stream.
- `[ ]` **Basic Gesture Detection**: Implement logic in `GestureInterpreter.kt` to accurately detect basic "Wave Up" and "Wave Down" motions based on landmark deltas over time.
- `[ ]` **Confidence Gate**: Add confidence thresholds to prevent false positives when interpreting gestures.

## Phase 3: Background Engine (v0.3)
- `[ ]` **Background Camera Processing**: Ensure `BackgroundCameraManager.kt` can capture frames headlessly without a visible preview surface.
- `[ ]` **Smart Wake Filter**: Integrate proximity and accelerometer sensor checks so the camera only activates when a hand approaches, saving battery.
- `[ ]` **Floating Overlay**: Add a system alert window (floating bubble) in Android to indicate when the background gesture engine is actively listening or detects a gesture.

## Phase 4: Full Customization (v0.4)
- `[ ]` **Gesture-to-Action Mapping Engine**: Implement the logic to execute specific actions (like scrolling or media playback) depending on the recognized gesture.
- `[ ]` **App Profiles Database**: Set up `sqflite` in Flutter to persist custom profiles for different apps (TikTok, YouTube, etc.).
- `[ ]` **Foreground App Matcher**: Implement detection of the currently active app so SpatialTouch can auto-switch profiles seamlessly.

## Phase 5: Polish & UX (v0.5)
- `[ ]` **Onboarding & Calibration Wizard**: Build the UI and logic in `lib/features/onboarding/` and `lib/features/calibration/` to tailor gesture detection to the user's hand size and environment.
- `[ ]` **Active Hours Scheduling**: Let users define times of day when the gesture service is active.
- `[ ]` **Performance Modes**: Implement Battery Saver / Balanced / Performance modes that adjust the detection FPS and cooldown timers.
- `[ ]` **Haptic Feedback**: Trigger vibrations through Flutter or Android upon successful gesture recognition.

## Phase 6: Release (v1.0)
- `[ ]` **Thorough Testing**: Test gesture accuracy across various lighting conditions and distances.
- `[ ]` **Documentation**: Finalize README, privacy policy, and user guides.
- `[ ]` **Demo Materials**: Record promotional/demo videos showing the app in action.
- `[ ]` **Play Store Deployment**: Submit the initial release to the Google Play Store.
