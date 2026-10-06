# SpatialTouch - User Guide

Welcome to **SpatialTouch**! This guide will walk you through setting up, calibrating, and using the application to control your Android device using touchless air gestures.

---

## 🚀 Quick Start Setup

To get SpatialTouch up and running, follow these steps:

### 1. Grant Android Permissions
SpatialTouch operates in the background to inject touch inputs. When you launch the app, you will be prompted to grant three key permissions:
*   **Camera Permission**: Used headlessly to track hand landmarks via Google MediaPipe. *Note: SpatialTouch does not save or transmit any video feed.*
*   **System Alert Window (Overlay)**: Enables the status bubble on your screen so you know when the gesture engine is active.
*   **Accessibility Service**: Allows the app to simulate physical taps, swipes, and system navigations (like Home and Back) touchlessly. Go to **Settings > Accessibility > Installed Services > SpatialTouch** and turn it **ON**.

### 2. Turn On the Service
*   Open the app to the **Home Screen**.
*   Tap the large circular **ON/OFF Toggle Button** in the center.
*   The status text will change to **"SERVICE RUNNING"** and the floating bubble overlay will appear in the top-right corner of your screen.

---

## 🛠️ Calibration Wizard

Before using SpatialTouch, we recommend running the calibration wizard to tailor detection to your environment.
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

SpatialTouch lets you map physical movements to device actions globally or for specific apps.

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
*   When you open these apps, SpatialTouch will automatically detect the foreground package and swap mapping profiles instantly.

---

## 🔋 Battery & Scheduler Polish

SpatialTouch runs natively in the background. To keep your device's battery healthy:

### 1. Smart Wake Filter
*   With **Smart Wake** on (Settings › Overlay & Performance), the camera stays off until your hand passes close to the phone's proximity sensor near the earpiece.
*   It then stays on for as long as it can see a hand, and sleeps after 10 seconds without one.
*   Phones without a proximity sensor keep the camera on while the service runs. Turn Smart Wake off if you'd rather never have to wake it.

### 2. Select a Performance Preset
Expand **Overlay & Performance** in the Settings tab:
*   **Battery Saver**: Operates at **5 FPS** with a **2000 ms cooldown**. Excellent for basic Kindle reading.
*   **Balanced**: Operates at **15 FPS** with an **800 ms cooldown**. Recommended for everyday swiping.
*   **Performance**: Operates at **30 FPS** with a **300 ms cooldown**. Best for fast-paced video apps, but consumes more battery.

### 3. Active Hours Schedule
Expand **Feedback & Schedule** in the Settings tab:
*   Toggle **Enable Active Hours**.
*   Select **Start Time** (e.g. 08:00 AM) and **End Time** (e.g. 10:00 PM).
*   Outside this window the service pauses the camera (the notification says so) and resumes on its own when the window opens. This keeps working with the app closed.

---

## ✋ Custom Gestures

*   In the **Gestures** tab, tap **+** to record your own hand pose (e.g. a peace sign).
*   Hold the pose still while each of the three samples records. Each sample is graded **Excellent**, **Good** or **Unsteady**.
*   Test it on the last step, save it, then open it in the Gestures tab to assign an action, globally or per app.
*   Custom gestures are static poses held for about half a second, not movements.

## 💡 Troubleshooting

*   **After restarting the phone**: Android doesn't let camera apps restart themselves on boot. Tap the **"SpatialTouch is paused"** notification to resume.

*   **Status overlay is red / sleeping**: Ensure the Accessibility Service is still turned on. Android sometimes battery-optimizes background services and shuts them off. Turn battery optimization to **"Unrestricted"** for SpatialTouch.
*   **Gestures are not registering**: Make sure you have enough ambient light. Standing directly under bright backlights (like a window behind you) can make it difficult for MediaPipe to separate your hand landmarks from the background.
*   **Too many false actions**: Redo calibration and increase the **Confidence Threshold** to `0.80` or `0.85`.
