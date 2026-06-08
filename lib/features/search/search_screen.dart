import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () => setState(() => _hasQuery = _controller.text.isNotEmpty),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            TextField(
              controller: _controller,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search Spartial Touch…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _controller.clear,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 28),

            // Recent / suggestions
            Text('Recent', style: tt.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _recentItems.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _recentItems[i];
                  return ListTile(
                    leading: Icon(item.icon,
                        color: cs.onSurfaceVariant, size: 20),
                    title: Text(item.label, style: tt.bodyLarge),
                    trailing: Icon(Icons.north_west_rounded,
                        size: 16, color: cs.outline),
                    onTap: () => _controller.text = item.label,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _recentItems = [
  _SearchItem(icon: Icons.history_rounded, label: 'Spatial audio setup'),
  _SearchItem(icon: Icons.history_rounded, label: 'Haptic feedback patterns'),
  _SearchItem(icon: Icons.history_rounded, label: 'Sensor calibration'),
  _SearchItem(icon: Icons.history_rounded, label: 'Device pairing'),
];

class _SearchItem {
  const _SearchItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
