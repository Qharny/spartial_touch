<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>SpatialTouch — README</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:ital,wght@0,400;0,700;1,400&family=Syne:wght@400;700;800&display=swap" rel="stylesheet"/>
<style>
  :root {
    --bg: #0a0a0f;
    --bg2: #111118;
    --bg3: #16161f;
    --border: #2a2a3a;
    --accent: #7c6dfa;
    --accent2: #03dac6;
    --accent3: #fa6d8a;
    --text: #e8e6f0;
    --muted: #7a7890;
    --code-bg: #13131c;
    --radius: 8px;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Space Mono', monospace;
    font-size: 14px;
    line-height: 1.8;
    padding: 0;
  }

  /* ── Hero ── */
  .hero {
    position: relative;
    overflow: hidden;
    padding: 80px 40px 64px;
    border-bottom: 1px solid var(--border);
  }

  .hero-grid {
    position: absolute;
    inset: 0;
    background-image:
      linear-gradient(var(--border) 1px, transparent 1px),
      linear-gradient(90deg, var(--border) 1px, transparent 1px);
    background-size: 40px 40px;
    opacity: 0.35;
  }

  .hero-glow {
    position: absolute;
    top: -120px; left: 50%;
    transform: translateX(-50%);
    width: 600px; height: 400px;
    background: radial-gradient(ellipse, rgba(124,109,250,0.18) 0%, transparent 70%);
    pointer-events: none;
  }

  .hero-content { position: relative; max-width: 860px; margin: 0 auto; }

  .badge {
    display: inline-block;
    font-size: 10px;
    font-family: 'Space Mono', monospace;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--accent2);
    border: 1px solid var(--accent2);
    padding: 3px 10px;
    border-radius: 2px;
    margin-bottom: 24px;
    opacity: 0;
    animation: fadeUp 0.5s 0.1s forwards;
  }

  .hero h1 {
    font-family: 'Syne', sans-serif;
    font-size: clamp(52px, 8vw, 88px);
    font-weight: 800;
    line-height: 1.0;
    letter-spacing: -0.02em;
    opacity: 0;
    animation: fadeUp 0.6s 0.2s forwards;
  }

  .hero h1 span { color: var(--accent); }

  .hero-sub {
    font-size: 15px;
    color: var(--muted);
    margin-top: 20px;
    max-width: 520px;
    opacity: 0;
    animation: fadeUp 0.6s 0.35s forwards;
  }

  .hero-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 36px;
    opacity: 0;
    animation: fadeUp 0.6s 0.45s forwards;
  }

  .pill {
    font-size: 11px;
    font-family: 'Space Mono', monospace;
    padding: 5px 14px;
    border-radius: 2px;
    border: 1px solid var(--border);
    color: var(--muted);
  }

  .pill.purple { border-color: var(--accent); color: var(--accent); background: rgba(124,109,250,0.08); }
  .pill.teal   { border-color: var(--accent2); color: var(--accent2); background: rgba(3,218,198,0.08); }
  .pill.pink   { border-color: var(--accent3); color: var(--accent3); background: rgba(250,109,138,0.08); }

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(16px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  /* ── Layout ── */
  .container { max-width: 860px; margin: 0 auto; padding: 0 40px; }

  /* ── Section titles ── */
  .section { padding: 56px 40px; border-bottom: 1px solid var(--border); }
  .section:last-child { border-bottom: none; }

  .section-label {
    font-size: 10px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    color: var(--accent);
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .section-label::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--border);
    max-width: 80px;
  }

  h2 {
    font-family: 'Syne', sans-serif;
    font-size: 28px;
    font-weight: 700;
    margin-bottom: 24px;
    letter-spacing: -0.01em;
  }

  h3 {
    font-family: 'Syne', sans-serif;
    font-size: 17px;
    font-weight: 700;
    margin: 28px 0 10px;
    color: var(--text);
  }

  p { color: var(--muted); margin-bottom: 14px; line-height: 1.9; }

  /* ── Code blocks ── */
  pre {
    background: var(--code-bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 20px 24px;
    overflow-x: auto;
    margin: 16px 0;
    font-size: 13px;
    line-height: 1.7;
  }

  code {
    font-family: 'Space Mono', monospace;
    font-size: 12px;
    color: var(--accent2);
  }

  pre code { color: var(--text); font-size: 13px; }

  .kw  { color: var(--accent); }
  .cm  { color: #4a4860; font-style: italic; }
  .str { color: var(--accent2); }
  .fn  { color: var(--accent3); }
  .num { color: #f0a86e; }

  /* ── Feature grid ── */
  .feat-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 1px;
    background: var(--border);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    margin-top: 24px;
  }

  .feat-card {
    background: var(--bg2);
    padding: 24px;
    transition: background 0.2s;
  }

  .feat-card:hover { background: var(--bg3); }

  .feat-icon {
    width: 36px; height: 36px;
    background: rgba(124,109,250,0.12);
    border: 1px solid rgba(124,109,250,0.3);
    border-radius: 6px;
    display: flex; align-items: center; justify-content: center;
    font-size: 16px;
    margin-bottom: 14px;
  }

  .feat-title {
    font-family: 'Syne', sans-serif;
    font-size: 14px;
    font-weight: 700;
    margin-bottom: 6px;
    color: var(--text);
  }

  .feat-desc { font-size: 12px; color: var(--muted); line-height: 1.7; margin: 0; }

  /* ── Table ── */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
    font-size: 13px;
  }

  thead th {
    text-align: left;
    font-family: 'Syne', sans-serif;
    font-size: 11px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: var(--muted);
    padding: 10px 16px;
    border-bottom: 1px solid var(--border);
  }

  tbody tr { border-bottom: 1px solid rgba(42,42,58,0.5); transition: background 0.15s; }
  tbody tr:hover { background: var(--bg2); }
  tbody td { padding: 12px 16px; color: var(--muted); vertical-align: top; }
  tbody td:first-child { color: var(--text); font-weight: 700; white-space: nowrap; }

  td .tag {
    display: inline-block;
    font-size: 10px;
    padding: 2px 8px;
    border-radius: 2px;
    font-family: 'Space Mono', monospace;
  }

  .tag-yes  { background: rgba(3,218,198,0.12); color: var(--accent2); border: 1px solid rgba(3,218,198,0.3); }
  .tag-no   { background: rgba(250,109,138,0.10); color: var(--accent3); border: 1px solid rgba(250,109,138,0.3); }
  .tag-part { background: rgba(240,168,110,0.12); color: #f0a86e; border: 1px solid rgba(240,168,110,0.3); }

  /* ── Steps ── */
  .steps { margin-top: 20px; }

  .step {
    display: flex;
    gap: 20px;
    padding: 20px 0;
    border-bottom: 1px solid var(--border);
  }
  .step:last-child { border-bottom: none; }

  .step-num {
    flex-shrink: 0;
    width: 32px; height: 32px;
    background: rgba(124,109,250,0.12);
    border: 1px solid rgba(124,109,250,0.4);
    border-radius: 4px;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Syne', sans-serif;
    font-size: 13px;
    font-weight: 700;
    color: var(--accent);
  }

  .step-body h4 {
    font-family: 'Syne', sans-serif;
    font-size: 14px;
    font-weight: 700;
    margin-bottom: 4px;
    color: var(--text);
  }

  .step-body p { font-size: 13px; margin: 0; color: var(--muted); }

  /* ── Inline code ── */
  p code, li code, td code {
    background: rgba(124,109,250,0.1);
    border: 1px solid rgba(124,109,250,0.25);
    padding: 1px 6px;
    border-radius: 3px;
    font-size: 12px;
    color: var(--accent);
  }

  /* ── Lists ── */
  ul { list-style: none; padding: 0; }
  ul li {
    padding: 5px 0 5px 18px;
    position: relative;
    color: var(--muted);
    font-size: 13px;
  }
  ul li::before {
    content: '›';
    position: absolute; left: 0;
    color: var(--accent);
    font-weight: 700;
  }

  /* ── Roadmap ── */
  .phases { display: flex; flex-direction: column; gap: 0; margin-top: 20px; }

  .phase {
    display: flex;
    gap: 0;
    position: relative;
  }

  .phase-line {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 40px;
    flex-shrink: 0;
  }

  .phase-dot {
    width: 12px; height: 12px;
    border-radius: 50%;
    background: var(--accent);
    border: 2px solid var(--bg);
    z-index: 1;
    margin-top: 6px;
  }

  .phase-dot.done { background: var(--accent2); }
  .phase-dot.future { background: var(--border); }

  .phase-track {
    width: 1px;
    flex: 1;
    background: var(--border);
    margin-top: 4px;
  }

  .phase:last-child .phase-track { display: none; }

  .phase-body {
    flex: 1;
    padding: 0 0 32px 16px;
  }

  .phase-tag {
    display: inline-block;
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    padding: 2px 8px;
    border-radius: 2px;
    margin-bottom: 8px;
    font-family: 'Space Mono', monospace;
  }

  .tag-v1 { background: rgba(124,109,250,0.15); color: var(--accent); border: 1px solid rgba(124,109,250,0.3); }
  .tag-v2 { background: rgba(3,218,198,0.10); color: var(--accent2); border: 1px solid rgba(3,218,198,0.3); }
  .tag-v3 { background: rgba(42,42,58,0.8); color: var(--muted); border: 1px solid var(--border); }

  .phase-title {
    font-family: 'Syne', sans-serif;
    font-size: 15px;
    font-weight: 700;
    color: var(--text);
    margin-bottom: 6px;
  }

  /* ── Gesture table ── */
  .gesture-row td:nth-child(2) { color: var(--accent2); font-family: 'Space Mono', monospace; font-size: 12px; }

  /* ── Footer ── */
  footer {
    padding: 40px;
    border-top: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 16px;
  }

  footer span { font-size: 12px; color: var(--muted); }

  .footer-brand {
    font-family: 'Syne', sans-serif;
    font-size: 18px;
    font-weight: 800;
    color: var(--accent);
  }

  /* ── Warning box ── */
  .callout {
    border-left: 3px solid var(--accent);
    background: rgba(124,109,250,0.07);
    padding: 16px 20px;
    border-radius: 0 var(--radius) var(--radius) 0;
    margin: 16px 0;
    font-size: 13px;
    color: var(--muted);
  }

  .callout.warn {
    border-color: #f0a86e;
    background: rgba(240,168,110,0.07);
  }

  .callout strong { color: var(--text); }

  /* ── Divider ── */
  hr { border: none; border-top: 1px solid var(--border); margin: 0; }

  /* ── Responsive ── */
  @media (max-width: 600px) {
    .hero, .section { padding: 40px 20px; }
    footer { padding: 32px 20px; }
    .hero h1 { font-size: 44px; }
  }
</style>
</head>
<body>

<!-- ── HERO ────────────────────────────────────────────────────── -->
<div class="hero">
  <div class="hero-grid"></div>
  <div class="hero-glow"></div>
  <div class="hero-content">
    <div class="badge">✦ v1.0 — Android · Flutter · MediaPipe</div>
    <h1>Spatial<span>Touch</span></h1>
    <p class="hero-sub">Control any Android app with mid-air hand gestures — no screen contact required. Built with Flutter, MediaPipe, and Android Accessibility Service.</p>
    <div class="hero-badges">
      <span class="pill purple">Flutter 3.x</span>
      <span class="pill teal">MediaPipe Hands</span>
      <span class="pill">Android 8.0+</span>
      <span class="pill pink">Accessibility Service</span>
      <span class="pill">100% on-device ML</span>
      <span class="pill teal">Play Store</span>
    </div>
  </div>
</div>

<!-- ── WHAT IS IT ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">01 — Overview</div>
    <h2>What is SpatialTouch?</h2>
    <p>SpatialTouch is an Android background service that uses your front-facing camera to detect hand gestures in real time and translate them into touch events — scrolls, swipes, taps, and more — inside any app on your device.</p>
    <p>Wave your hand to scroll TikTok. Open your palm to pause YouTube. Point up to skip to the top of a feed. No touch. No voice. Just air.</p>

    <div class="callout">
      <strong>Privacy-first.</strong> All gesture detection runs locally using MediaPipe. No camera frames are ever transmitted, saved to disk, or sent to any server. Zero data collection.
    </div>

    <h3>Key highlights</h3>
    <ul>
      <li>13 built-in gestures, fully remappable per app</li>
      <li>Per-app profiles (TikTok, YouTube, Spotify, Maps, and more)</li>
      <li>Smart wake via proximity sensor — camera only activates when needed</li>
      <li>Floating overlay indicator with full customisation</li>
      <li>Battery Saver, Balanced, and Performance modes</li>
      <li>Guided onboarding with step-by-step permission setup</li>
    </ul>
  </div>
</div>

<!-- ── FEATURES ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">02 — Features</div>
    <h2>Core features</h2>
    <div class="feat-grid">
      <div class="feat-card">
        <div class="feat-icon">✦</div>
        <div class="feat-title">Background engine</div>
        <p class="feat-desc">Persistent Android Foreground Service runs MediaPipe inference while you use any other app.</p>
      </div>
      <div class="feat-card">
        <div class="feat-icon">◎</div>
        <div class="feat-title">Smart wake</div>
        <p class="feat-desc">Proximity + accelerometer pre-filter — camera only wakes when a hand is likely nearby.</p>
      </div>
      <div class="feat-card">
        <div class="feat-icon">⬡</div>
        <div class="feat-title">App profiles</div>
        <p class="feat-desc">Different gesture mappings per app. Auto-switches when you change foreground app.</p>
      </div>
      <div class="feat-card">
        <div class="feat-icon">⌘</div>
        <div class="feat-title">Full customisation</div>
        <p class="feat-desc">Map any gesture to any action. Tune sensitivity, confidence, and cooldown per gesture.</p>
      </div>
      <div class="feat-card">
        <div class="feat-icon">◈</div>
        <div class="feat-title">Floating overlay</div>
        <p class="feat-desc">Draggable indicator bubble. Fully configurable — size, opacity, colour, or hidden entirely.</p>
      </div>
      <div class="feat-card">
        <div class="feat-icon">⟳</div>
        <div class="feat-title">Active hours</div>
        <p class="feat-desc">Schedule the service to run only between set times. Saves battery overnight.</p>
      </div>
    </div>
  </div>
</div>

<!-- ── GESTURES ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">03 — Gestures</div>
    <h2>Gesture library</h2>
    <p>13 gestures ship in v1.0. Every gesture can be remapped to any action or disabled entirely.</p>
    <table>
      <thead>
        <tr>
          <th>Gesture</th>
          <th>Motion</th>
          <th>Default action</th>
        </tr>
      </thead>
      <tbody class="gesture-row">
        <tr><td>Wave up</td><td>Hand moves upward quickly</td><td>Scroll up</td></tr>
        <tr><td>Wave down</td><td>Hand moves downward quickly</td><td>Scroll down</td></tr>
        <tr><td>Wave left</td><td>Hand sweeps left across FOV</td><td>Swipe left</td></tr>
        <tr><td>Wave right</td><td>Hand sweeps right across FOV</td><td>Swipe right</td></tr>
        <tr><td>Open palm hold</td><td>Flat open palm held 1–2 s</td><td>Pause / Play</td></tr>
        <tr><td>Thumbs up</td><td>Fist with thumb extended up</td><td>Like / Upvote</td></tr>
        <tr><td>Thumbs down</td><td>Fist with thumb extended down</td><td>Dislike</td></tr>
        <tr><td>Index point up</td><td>Index finger extended upward</td><td>Scroll to top</td></tr>
        <tr><td>Pinch</td><td>Thumb + index finger close</td><td>Zoom in</td></tr>
        <tr><td>Two-finger swipe R</td><td>Index + middle sweep right</td><td>Go forward</td></tr>
        <tr><td>Two-finger swipe L</td><td>Index + middle sweep left</td><td>Go back</td></tr>
        <tr><td>Fist pump</td><td>Closed fist toward camera</td><td>Screenshot</td></tr>
        <tr><td>Rock sign</td><td>Index + pinky extended</td><td>Custom shortcut</td></tr>
      </tbody>
    </table>
  </div>
</div>

<!-- ── GETTING STARTED ────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">04 — Setup</div>
    <h2>Getting started</h2>

    <h3>Prerequisites</h3>
    <ul>
      <li>Flutter 3.x (<code>flutter --version</code>)</li>
      <li>Android SDK — minimum API 26 (Android 8.0), target API 34</li>
      <li>A physical Android device (camera required — emulator won't work)</li>
      <li>USB debugging enabled on the device</li>
    </ul>

    <h3>Clone &amp; run</h3>
    <pre><code><span class="cm"># Clone the repo</span>
git clone https://github.com/yourname/spatialtouch.git
cd spatialtouch

<span class="cm"># Install Flutter dependencies</span>
flutter pub get

<span class="cm"># Connect your Android device, then run</span>
flutter run --release</code></pre>

    <h3>Build APK</h3>
    <pre><code>flutter build apk --release
<span class="cm"># Output: build/app/outputs/flutter-apk/app-release.apk</span></code></pre>

    <h3>Build App Bundle (Play Store)</h3>
    <pre><code>flutter build appbundle --release
<span class="cm"># Output: build/app/outputs/bundle/release/app-release.aab</span></code></pre>

    <h3>First launch — permission checklist</h3>
    <div class="steps">
      <div class="step">
        <div class="step-num">1</div>
        <div class="step-body">
          <h4>Camera permission</h4>
          <p>Tap <strong>Grant Camera Access</strong> and allow. Used only on-device for gesture detection.</p>
        </div>
      </div>
      <div class="step">
        <div class="step-num">2</div>
        <div class="step-body">
          <h4>Accessibility Service</h4>
          <p>The app deep-links you to <strong>Settings › Accessibility › SpatialTouch</strong>. Toggle it on. This is what allows touch event injection.</p>
        </div>
      </div>
      <div class="step">
        <div class="step-num">3</div>
        <div class="step-body">
          <h4>Draw over other apps</h4>
          <p>Optional but recommended. Enables the floating gesture indicator overlay.</p>
        </div>
      </div>
      <div class="step">
        <div class="step-num">4</div>
        <div class="step-body">
          <h4>Calibration</h4>
          <p>Follow the on-screen calibration wizard — sets optimal detection distance and lighting thresholds for your environment.</p>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- ── PROJECT STRUCTURE ────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">05 — Structure</div>
    <h2>Project structure</h2>
    <pre><code>spatialtouch/
├── android/
│   └── app/src/main/kotlin/
│       ├── <span class="fn">SpatialTouchAccessibilityService.kt</span>   <span class="cm"># Touch injection</span>
│       ├── <span class="fn">GestureBackgroundService.kt</span>          <span class="cm"># Foreground service</span>
│       └── <span class="fn">MainActivity.kt</span>                      <span class="cm"># MethodChannel host</span>
│
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── <span class="fn">gesture_interpreter.dart</span>             <span class="cm"># Landmark → gesture</span>
│   │   ├── <span class="fn">action_dispatcher.dart</span>               <span class="cm"># Gesture → action</span>
│   │   └── <span class="fn">profile_matcher.dart</span>                 <span class="cm"># App → profile lookup</span>
│   ├── data/
│   │   ├── <span class="fn">profile_repository.dart</span>              <span class="cm"># SQLite CRUD</span>
│   │   └── <span class="fn">settings_repository.dart</span>             <span class="cm"># SharedPreferences</span>
│   ├── features/
│   │   ├── dashboard/
│   │   ├── profiles/
│   │   ├── gestures/
│   │   ├── settings/
│   │   ├── onboarding/
│   │   └── tester/
│   └── shared/
│       ├── <span class="fn">overlay_widget.dart</span>
│       └── <span class="fn">theme.dart</span>
│
├── pubspec.yaml
└── README.md</code></pre>
  </div>
</div>

<!-- ── TECH STACK ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">06 — Stack</div>
    <h2>Tech stack</h2>
    <table>
      <thead>
        <tr><th>Layer</th><th>Technology</th><th>Android</th><th>iOS</th></tr>
      </thead>
      <tbody>
        <tr><td>UI framework</td><td>Flutter 3.x (Dart)</td><td class="tag-yes-cell"><span class="tag tag-yes">✓</span></td><td><span class="tag tag-yes">✓</span></td></tr>
        <tr><td>State management</td><td>Riverpod / BLoC</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-yes">✓</span></td></tr>
        <tr><td>ML / hand tracking</td><td>MediaPipe Hands</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-yes">✓</span></td></tr>
        <tr><td>Background camera</td><td>CameraX + Foreground Service</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-no">✗</span></td></tr>
        <tr><td>Touch injection</td><td>Android AccessibilityService</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-no">✗</span></td></tr>
        <tr><td>Native bridge</td><td>Flutter MethodChannel</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-part">partial</span></td></tr>
        <tr><td>Local storage</td><td>sqflite (SQLite)</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-yes">✓</span></td></tr>
        <tr><td>Preferences</td><td>shared_preferences</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-yes">✓</span></td></tr>
        <tr><td>Platform SDK</td><td>Kotlin (Android native)</td><td><span class="tag tag-yes">✓</span></td><td><span class="tag tag-no">✗</span></td></tr>
      </tbody>
    </table>

    <div class="callout warn">
      <strong>iOS note.</strong> Full background gesture control is not possible on iOS due to platform restrictions on background camera access and touch injection. A limited foreground-only mode may be added in a future release.
    </div>
  </div>
</div>

<!-- ── ROADMAP ────────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">07 — Roadmap</div>
    <h2>Roadmap</h2>
    <div class="phases">

      <div class="phase">
        <div class="phase-line"><div class="phase-dot done"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v0.1</span>
          <div class="phase-title">Foundation</div>
          <ul><li>Flutter + Kotlin hybrid project setup</li><li>Android Foreground Service scaffolding</li><li>AccessibilityService — simulate scroll events</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot done"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v0.2</span>
          <div class="phase-title">Vision core</div>
          <ul><li>MediaPipe Hands integration</li><li>Live camera preview with landmark overlay</li><li>Wave up / down → scroll events</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v0.3</span>
          <div class="phase-title">Background magic</div>
          <ul><li>MediaPipe moved into Foreground Service</li><li>Smart wake via proximity sensor</li><li>Floating overlay indicator</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v0.4</span>
          <div class="phase-title">Full customisation</div>
          <ul><li>Complete 13-gesture library</li><li>App profiles system</li><li>Gesture → action mapping UI</li><li>SQLite storage</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v0.5</span>
          <div class="phase-title">Polish &amp; UX</div>
          <ul><li>Full onboarding flow</li><li>Calibration wizard</li><li>Active hours scheduling</li><li>Battery monitor</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v1">v1.0</span>
          <div class="phase-title">Play Store release</div>
          <ul><li>Final design polish</li><li>Privacy policy + Play Store listing</li><li>Demo video</li><li>Public release</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot future"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v2">v2.0</span>
          <div class="phase-title">Custom gesture recording</div>
          <ul><li>Train the app with your own gestures</li><li>Two-hand combinations</li><li>iOS foreground-only mode</li></ul>
        </div>
      </div>

      <div class="phase">
        <div class="phase-line"><div class="phase-dot future"></div><div class="phase-track"></div></div>
        <div class="phase-body">
          <span class="phase-tag tag-v3">v3.0</span>
          <div class="phase-title">Future</div>
          <ul><li>Gesture macros (one gesture → sequence of actions)</li><li>Community profile sharing</li><li>WearOS trigger</li><li>PC companion app</li></ul>
        </div>
      </div>

    </div>
  </div>
</div>

<!-- ── PERMISSIONS ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">08 — Permissions</div>
    <h2>Required permissions</h2>
    <table>
      <thead><tr><th>Permission</th><th>Why</th></tr></thead>
      <tbody>
        <tr><td><code>CAMERA</code></td><td>Front camera for hand gesture detection (on-device only)</td></tr>
        <tr><td><code>FOREGROUND_SERVICE</code></td><td>Keep gesture engine running in background</td></tr>
        <tr><td><code>FOREGROUND_SERVICE_CAMERA</code></td><td>Android 14+ requirement for background camera use</td></tr>
        <tr><td><code>SYSTEM_ALERT_WINDOW</code></td><td>Draw floating overlay indicator over other apps</td></tr>
        <tr><td><code>AccessibilityService</code></td><td>Inject scroll, tap, and swipe events into the foreground app</td></tr>
        <tr><td><code>RECEIVE_BOOT_COMPLETED</code></td><td>Auto-start service on device reboot (if enabled by user)</td></tr>
        <tr><td><code>VIBRATE</code></td><td>Haptic feedback on gesture recognition</td></tr>
      </tbody>
    </table>
  </div>
</div>

<!-- ── CONTRIBUTING ────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">09 — Contributing</div>
    <h2>Contributing</h2>
    <p>Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.</p>

    <h3>Dev workflow</h3>
    <pre><code><span class="cm"># Create a feature branch</span>
git checkout -b feat/your-feature-name

<span class="cm"># Run tests</span>
flutter test

<span class="cm"># Analyse code</span>
flutter analyze

<span class="cm"># Format</span>
dart format lib/</code></pre>

    <h3>Commit convention</h3>
    <ul>
      <li><code>feat:</code> new feature</li>
      <li><code>fix:</code> bug fix</li>
      <li><code>perf:</code> performance improvement</li>
      <li><code>refactor:</code> code change, no new feature</li>
      <li><code>docs:</code> documentation only</li>
      <li><code>chore:</code> build / tooling</li>
    </ul>
  </div>
</div>

<!-- ── LICENSE ────────────────────────────────────────────────────── -->
<div class="section">
  <div class="container">
    <div class="section-label">10 — License</div>
    <h2>License</h2>
    <p>MIT License — see <code>LICENSE</code> for full text.</p>
    <p>MediaPipe is licensed under the Apache 2.0 License. Flutter is licensed under the BSD 3-Clause License.</p>
  </div>
</div>

<!-- ── FOOTER ─────────────────────────────────────────────────────── -->
<footer>
  <span class="footer-brand">SpatialTouch</span>
  <span>Built with Flutter · MediaPipe · Android Accessibility API</span>
  <span>v1.0 · 2025 · MIT License</span>
</footer>

</body>
</html>
