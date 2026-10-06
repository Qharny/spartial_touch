import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:spartial_touch/core/models/gesture_catalog.dart';
import 'package:spartial_touch/core/models/profile_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const channel = MethodChannel('kabuteyy.spartial_touch/gestures');
  late List<Map<String, Map<String, String>>> pushes;

  /// The last full profile set pushed to the native ActionDispatcher.
  Map<String, Map<String, String>> lastPushed() => pushes.last;

  setUp(() async {
    // Fresh, re-seeded database for every test.
    await ProfileDatabase.instance.close();
    await databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'spatialtouch.db'));

    pushes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'loadProfiles') {
        pushes.add({
          for (final e in (call.arguments as Map).entries)
            e.key as String: {
              for (final m in (e.value as Map).entries) m.key as String: m.value as String,
            },
        });
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await ProfileDatabase.instance.close();
  });

  final db = ProfileDatabase.instance;

  test('a fresh install exposes the seeded global action and app overrides', () async {
    final b = await db.getBindingsForGesture('WAVE_UP');

    expect(b.globalActionId, 'scroll_up');
    final spotify = b.overrides.singleWhere((o) => o.packageName == 'com.spotify.music');
    expect(spotify.actionId, 'volume_up');
  });

  test('assigning a new app override stores it and pushes it to native', () async {
    await db.setBinding(
      packageName: 'com.example.reader',
      displayName: 'Reader',
      gestureKey: 'PINCH',
      actionId: 'screenshot',
    );

    final b = await db.getBindingsForGesture('PINCH');
    expect(b.globalActionId, isNull);
    expect(b.overrides.single.packageName, 'com.example.reader');
    expect(b.overrides.single.actionId, 'screenshot');
    expect(lastPushed()['com.example.reader'], {'PINCH': 'screenshot'});
  });

  test('changing an override replaces it instead of duplicating', () async {
    for (final action in ['scroll_up', 'home']) {
      await db.setBinding(
        packageName: 'com.example.reader',
        displayName: 'Reader',
        gestureKey: 'THUMBS_UP',
        actionId: action,
      );
    }

    // THUMBS_UP is already seeded for Instagram, so filter to the app we edited.
    final b = await db.getBindingsForGesture('THUMBS_UP');
    final reader = b.overrides.where((o) => o.packageName == 'com.example.reader');
    expect(reader, hasLength(1));
    expect(reader.single.actionId, 'home');
  });

  test('clearing an override removes only that app and leaves the global action', () async {
    await db.setBinding(
      packageName: 'com.spotify.music',
      displayName: 'Spotify',
      gestureKey: 'WAVE_UP',
      actionId: null,
    );

    final b = await db.getBindingsForGesture('WAVE_UP');
    expect(b.overrides.any((o) => o.packageName == 'com.spotify.music'), isFalse);
    expect(b.globalActionId, 'scroll_up');
    // Spotify's other gestures are untouched.
    expect(lastPushed()['com.spotify.music']!.containsKey('WAVE_UP'), isFalse);
    expect(lastPushed()['com.spotify.music']!['WAVE_LEFT'], 'media_previous');
  });

  test('clearing a binding for an app with no profile creates nothing', () async {
    await db.setBinding(
      packageName: 'com.example.ghost',
      displayName: 'Ghost',
      gestureKey: 'PINCH',
      actionId: null,
    );

    final profiles = await db.getAllProfiles();
    expect(profiles.any((p) => p.packageName == 'com.example.ghost'), isFalse);
  });

  test('setting the global action does not touch app overrides', () async {
    await db.setBinding(
      packageName: kDefaultProfilePackage,
      displayName: 'Default',
      gestureKey: 'WAVE_UP',
      actionId: 'home',
    );

    final b = await db.getBindingsForGesture('WAVE_UP');
    expect(b.globalActionId, 'home');
    expect(b.overrides.any((o) => o.packageName == 'com.spotify.music'), isTrue);
    expect((await db.getGlobalActions())['WAVE_UP'], 'home');
  });

  test('assigning on a disabled profile re-enables it so it reaches native', () async {
    final tiktok = (await db.getAllProfiles()).singleWhere((p) => p.packageName == 'com.zhiliaoapp.musically');
    await db.updateProfile(tiktok.copyWith(enabled: false));
    await db.syncToNative();
    expect(lastPushed().containsKey('com.zhiliaoapp.musically'), isFalse);

    await db.setBinding(
      packageName: 'com.zhiliaoapp.musically',
      displayName: 'TikTok',
      gestureKey: 'PINCH',
      actionId: 'tap',
    );

    expect(lastPushed()['com.zhiliaoapp.musically']!['PINCH'], 'tap');
  });

  test('every action id in the catalog is one native understands', () {
    // Guards drift between kActions and ActionDispatcher.execute().
    const native = {
      'scroll_up', 'scroll_down', 'swipe_left', 'swipe_right', 'tap',
      'back', 'home', 'recents',
      'media_play_pause', 'media_next', 'media_previous',
      'volume_up', 'volume_down', 'screenshot',
    };
    expect(kActions.map((a) => a.id).toSet(), native);
  });
}
