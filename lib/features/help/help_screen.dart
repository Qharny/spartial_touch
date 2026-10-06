import 'package:flutter/material.dart';
import '../../core/router/router.dart';

/// In-app guide: setup, gestures, custom gestures, battery and troubleshooting.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _sections = <(IconData, String, List<String>)>[
    (Icons.rocket_launch_outlined, 'Getting started', [
      'Grant Camera access. Frames are processed on the phone and never saved or sent anywhere.',
      'Turn on the SpatialTouch Accessibility Service (Settings › Accessibility › Installed apps). It is what performs scrolls, swipes, taps and Back/Home for you.',
      'Allow "Display over other apps" if you want the floating status pill.',
      'Tap the big ring on Home. It turns amber and reads SERVICE RUNNING.',
    ]),
    (Icons.back_hand_outlined, 'Using gestures', [
      'Rest the phone on a table or stand and keep your hand 30–80 cm from the front camera.',
      'Waves are quick, deliberate movements of the whole hand. Poses (thumbs up, pinch, rock sign) need to be held briefly.',
      'Open Palm Hold needs a flat palm held still for about 1.2 seconds.',
      'Use the Live tab or the camera tester to see what the engine recognises.',
    ]),
    (Icons.tune_rounded, 'Assigning actions', [
      'Open a gesture in the Gestures tab to give it a global action.',
      'Add per-app overrides there, or use Settings › Connected Apps. The same wave can scroll in one app and skip tracks in another.',
      'Per-app actions need Usage access, so SpatialTouch can tell which app is open.',
      'The sensitivity slider on each gesture trades easier triggering against accidental activations.',
    ]),
    (Icons.add_circle_outline_rounded, 'Custom gestures', [
      'Tap + in the Gestures tab to record your own hand pose.',
      'Hold the pose steady while each of the three samples records. Steadier samples give better recognition.',
      'Test it on the last step, then save and assign it an action like any built-in gesture.',
      'Custom gestures are static poses: the shape of your hand, held for about half a second.',
    ]),
    (Icons.battery_saver_outlined, 'Battery', [
      'Smart Wake keeps the camera off until your hand comes near the phone, then stays on while it can see a hand and sleeps after 10 idle seconds.',
      'Performance presets set the camera frame rate and the cooldown between gestures. Battery Saver is 5 fps, Balanced 15 fps and Performance 30 fps.',
      'Active Hours pauses the camera outside the hours you choose.',
    ]),
    (Icons.build_outlined, 'Troubleshooting', [
      'Nothing happens: check the Accessibility Service is still on. Some phones turn it off after updates or battery optimisation.',
      'Set SpatialTouch\'s battery usage to "Unrestricted" so the system doesn\'t stop it in the background.',
      'Missed gestures: improve the lighting, avoid a bright window behind you, and redo calibration.',
      'Too many accidental actions: raise the confidence threshold in calibration or lower that gesture\'s sensitivity.',
      'After restarting your phone, tap the "SpatialTouch is paused" notification to resume. Android doesn\'t let camera apps restart themselves on boot.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Tutorials',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (icon, title, items) in _sections)
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(icon, color: cs.onSurface),
                title: Text(title,
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: cs.onSurface)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 10),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: cs.onSurfaceVariant, shape: BoxShape.circle),
                            ),
                          ),
                          Expanded(
                            child: Text(item,
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 14, height: 1.45, color: cs.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.calibration),
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Run calibration'),
          ),
        ],
      ),
    );
  }
}
