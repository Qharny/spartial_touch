import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'profile.dart';

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
            FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
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

  Future<int> insertProfile(AppProfile profile) async {
    final db = await _database;
    final profileId = await db.insert('profiles', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final mapping in profile.mappings) {
      await db.insert('gesture_mappings', mapping.toMap(profileId),
          conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<void> close() async {
    final db = await _database;
    await db.close();
    _db = null;
  }
}
