import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColorsDark.cardGradient
                    : AppColorsLight.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline),
              ),
              child: const Center(
                child: Icon(
                  Icons.spatial_audio_off_rounded,
                  size: 64,
                  color: AppColorsShared.accent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Item Title', style: tt.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'This is a placeholder for an item detail screen. '
              'Replace with your actual content and data.',
              style: tt.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
