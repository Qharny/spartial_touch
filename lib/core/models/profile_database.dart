import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'profile.dart';
import '../services/gesture_channel.dart';

/// SQLite-backed repository for [AppProfile] and [GestureMapping] persistence.
class ProfileDatabase {
  ProfileDatabase._();
  static final ProfileDatabase instance = ProfileDatabase._();

  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'spatialtouch.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package_name TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE gesture_mappings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            gesture_key TEXT NOT NULL,
            action_label TEXT NOT NULL,
            action_id TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
            UNIQUE (profile_id, gesture_key)
          )
        ''');
        // Seed built-in profiles on first launch
        await _seedProfiles(db);
      },
    );
  }

  Future<void> _seedProfiles(Database db) async {
    for (final profile in builtInProfiles) {
      final profileId = await db.insert('profiles', profile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      for (final mapping in profile.mappings) {
        await db.insert('gesture_mappings', mapping.toMap(profileId),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // ── Profiles ─────────────────────────────────────────────────────────────────

  Future<List<AppProfile>> getAllProfiles() async {
    final db = await _database;
    final profileRows = await db.query('profiles', orderBy: 'display_name ASC');
    final List<AppProfile> results = [];
    for (final row in profileRows) {
      final id = row['id'] as int;
      final mappingRows = await db.query('gesture_mappings',
          where: 'profile_id = ?', whereArgs: [id]);
      final mappings = mappingRows.map(GestureMapping.fromMap).toList();
      results.add(AppProfile.fromMap(row, mappings: mappings));
    }
    return results;
  }

  Future<AppProfile?> getProfileByPackage(String packageName) async {
    final db = await _database;
    final rows = await db.query('profiles',
        where: 'package_name = ?', whereArgs: [packageName]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final id = row['id'] as int;
    final mappingRows = await db.query('gesture_mappings',
        where: 'profile_id = ? AND enabled = 1', whereArgs: [id]);
    final mappings = mappingRows.map(GestureMapping.fromMap).toList();
    return AppProfile.fromMap(row, mappings: mappings);
  }

  /// Inserts a new profile, or — if [profile.packageName] already has a row —
  /// updates it and replaces its mappings in place.
  ///
  /// Previously this used `ConflictAlgorithm.replace` keyed on the UNIQUE
  /// `package_name` column. SQLite's REPLACE resolves a unique-constraint
  /// conflict by deleting the old row and inserting a new one, which gets a
  /// *new* autoincrement id — and since sqflite doesn't enable foreign-key
  /// enforcement by default, the `ON DELETE CASCADE` on `gesture_mappings`
  /// never fired, so the old profile's mappings were orphaned (kept in the
  /// table under the now-nonexistent old id) every time an existing profile
  /// was re-saved. Looking the row up first preserves its id, so mappings
  /// stay attached to it instead of leaking.
  Future<int> insertProfile(AppProfile profile) async {
    final db = await _database;
    final existing = await db.query('profiles',
        where: 'package_name = ?', whereArgs: [profile.packageName]);

    final int profileId;
    if (existing.isNotEmpty) {
      profileId = existing.first['id'] as int;
      await db.update('profiles', profile.toMap(),
          where: 'id = ?', whereArgs: [profileId]);
      await db.delete('gesture_mappings',
          where: 'profile_id = ?', whereArgs: [profileId]);
    } else {
      profileId = await db.insert('profiles', profile.toMap());
    }

    for (final mapping in profile.mappings) {
      await db.insert('gesture_mappings', mapping.toMap(profileId));
    }
    return profileId;
  }

  Future<void> updateProfile(AppProfile profile) async {
    final db = await _database;
    await db.update('profiles', profile.toMap(),
        where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<void> deleteProfile(int profileId) async {
    final db = await _database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    await db.delete('gesture_mappings',
        where: 'profile_id = ?', whereArgs: [profileId]);
  }

  // ── Gesture Mappings ─────────────────────────────────────────────────────────

  Future<void> upsertMapping(int profileId, GestureMapping mapping) async {
    final db = await _database;
    await db.insert('gesture_mappings', mapping.toMap(profileId),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMapping(int mappingId) async {
    final db = await _database;
    await db.delete('gesture_mappings', where: 'id = ?', whereArgs: [mappingId]);
  }

  // ── Native sync ──────────────────────────────────────────────────────────────

  /// Pushes every enabled profile's enabled mappings to the native
  /// `ActionDispatcher` via [GestureChannel.loadProfiles]. `loadProfileMappings`
  /// on the native side replaces its whole cache each call, so this always
  /// sends the full set — call it after any profile edit, and once at app
  /// startup so the engine isn't running with an empty mapping cache.
  Future<void> syncToNative() async {
    final profiles = await getAllProfiles();
    final payload = <String, Map<String, String>>{};
    for (final profile in profiles) {
      if (!profile.enabled) continue;
      final mappings = <String, String>{
        for (final m in profile.mappings)
          if (m.enabled) m.gestureKey: m.actionId,
      };
      payload[profile.packageName] = mappings;
    }
    await GestureChannel.loadProfiles(payload);
  }

  Future<void> close() async {
    final db = await _database;
    await db.close();
    _db = null;
  }
}
