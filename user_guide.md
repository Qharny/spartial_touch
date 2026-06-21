# Spartial Touch - User Guide

Welcome to **Spartial Touch**! This guide will walk you through setting up, calibrating, and using the application to control your Android device using touchless air gestures.

---

## 🚀 Quick Start Setup

To get Spartial Touch up and running, follow these steps:

### 1. Grant Android Permissions
Spartial Touch operates in the background to inject touch inputs. When you launch the app, you will be prompted to grant three key permissions:
*   **Camera Permission**: Used headlessly to track hand landmarks via Google MediaPipe. *Note: Spartial Touch does not save or transmit any video feed.*
*   **System Alert Window (Overlay)**: Enables the status bubble on your screen so you know when the gesture engine is active.
*   **Accessibility Service**: Allows the app to simulate physical taps, swipes, and system navigations (like Home and Back) touchlessly. Go to **Settings > Accessibility > Installed Services > Spartial Touch** and turn it **ON**.

### 2. Turn On the Service
*   Open the app to the **Home Screen**.
*   Tap the large circular **ON/OFF Toggle Button** in the center.
*   The status text will change to **"SERVICE RUNNING"** and the floating bubble overlay will appear in the top-right corner of your screen.

---

## 🛠️ Calibration Wizard

Before using Spartial Touch, we recommend running the calibration wizard to tailor detection to your environment.
1.  Go to the **Settings** tab (represented by the cog icon / profile screen).
2.  Expand **Calibration & Permissions** and tap **Redo Calibration**.
3.  Position your device stably on a table or stand.
4.  Stand/sit at your typical usage distance (usually **30cm – 80cm** from the front camera).
5.  Adjust the sliders:
    *   **Confidence Threshold**: Increase if you see ghost gestures (false triggers) in complex lighting, or decrease if the app is struggling to see your hand.
    *   **Motion Threshold**: Increase if slight hand shakes trigger swipes, or decrease if you want swipes to trigger with smaller, faster movements.
6.  Tap **Save Calibration** to apply settings instantly.

---

## 🎨 Mapping Gestures to Actions

Spartial Touch lets you map physical movements to device actions globally or for specific apps.

### Supported Gestures & Default Actions
| Gesture | Physical Motion | Default Action | Difficulty |
| :--- | :--- | :--- | :--- |
| **Wave Up** | Hand moves upward quickly | Scroll Up | Easy |
| **Wave Down** | Hand moves downward quickly | Scroll Down | Easy |
| **Wave Left** | Hand swipes left across FOV | Swipe Left | Easy |
| **Wave Right** | Hand swipes right across FOV | Swipe Right | Easy |
| **Open Palm Hold** | Flat open palm held for 1–2s | Pause / Play Media | Easy |
| **Thumbs Up** | Fist with thumb extended upward | Like / Upvote | Medium |
| **Thumbs Down** | Fist with thumb extended downward| Dislike | Medium |
| **Index Point Up** | Index finger extended upward | Scroll to Top | Medium |
| **Pinch** | Thumb and index finger touch | Zoom In | Medium |
| **Two-Finger Swipe R**| Index + middle finger sweep right| Go Forward | Medium |
| **Two-Finger Swipe L**| Index + middle finger sweep left | Go Back | Medium |
| **Fist Pump** | Closed fist pushed toward camera | Take Screenshot | Hard |
| **Rock Sign** | Index + pinky extended | Custom Shortcut | Hard |

### Customizing App Mappings
*   Go to **Settings > Connected Apps**.
*   Configure custom actions for apps like **TikTok, YouTube, Kindle**, etc. 
*   When you open these apps, Spartial Touch will automatically detect the foreground package and swap mapping profiles instantly.

---

## 🔋 Battery & Scheduler Polish

Spartial Touch runs natively in the background. To keep your device's battery healthy:

### 1. Smart Wake Filter
*   The camera feed is gated by proximity and motion sensors.
*   The camera only wakes up and begins MediaPipe detection when your hand approaches the screen. It returns to sleep when you put your hand down.

### 2. Select a Performance Preset
Expand **Overlay & Performance** in the Settings tab:
*   **Battery Saver**: Operates at **5 FPS** with a **2000 ms cooldown**. Excellent for basic Kindle reading.
*   **Balanced**: Operates at **15 FPS** with an **800 ms cooldown**. Recommended for everyday swiping.
*   **Performance**: Operates at **30 FPS** with a **300 ms cooldown**. Best for fast-paced video apps, but consumes more battery.

### 3. Active Hours Schedule
Expand **Feedback & Schedule** in the Settings tab:
*   Toggle **Enable Active Hours**.
*   Select **Start Time** (e.g. 08:00 AM) and **End Time** (e.g. 10:00 PM).
*   The background service will automatically turn off outside this window to conserve battery overnight.

---

## 💡 Troubleshooting

*   **Status overlay is red / sleeping**: Ensure the Accessibility Service is still turned on. Android sometimes battery-optimizes background services and shuts them off. Turn battery optimization to **"Unrestricted"** for Spartial Touch.
*   **Gestures are not registering**: Make sure you have enough ambient light. Standing directly under bright backlights (like a window behind you) can make it difficult for MediaPipe to separate your hand landmarks from the background.
*   **Too many false actions**: Redo calibration and increase the **Confidence Threshold** to `0.80` or `0.85`.
