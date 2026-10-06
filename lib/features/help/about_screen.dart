import 'package:flutter/material.dart';
import '../../core/app_info.dart';
import '../../core/router/router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/logo.png', width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Text(kAppName,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 28, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(kAppTagline,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Version $kAppVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Space Mono', fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          Text(
            'Hand tracking runs entirely on your phone with Google MediaPipe. '
            'Camera frames are processed in memory and never saved or sent anywhere. '
            'There are no accounts, analytics or ads.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Permissions & privacy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open-source licences'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationVersion: kAppVersion,
            ),
          ),
        ],
      ),
    );
  }
}
