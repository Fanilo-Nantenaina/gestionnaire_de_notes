import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'notes_app.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      category TEXT NOT NULL,
      tags TEXT,
      is_favorite INTEGER DEFAULT 0,
      humanitarian_data TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_encrypted INTEGER DEFAULT 0
    )
  ''');

    await db.execute('''
      CREATE TABLE activation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activation_key TEXT NOT NULL,
        device_id TEXT NOT NULL,
        activated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activation_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_hash TEXT NOT NULL UNIQUE,
        key_full TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        device_id TEXT,
        created_at TEXT NOT NULL,
        activated_at TEXT,
        revoked_at TEXT,
        revoke_reason TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_notes_category ON notes(category)');
    await db.execute('CREATE INDEX idx_notes_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX idx_notes_is_favorite ON notes(is_favorite)');
    await db.execute('CREATE INDEX idx_activation_keys_serial ON activation_keys(serial_hash)');
    await db.execute('CREATE INDEX idx_activation_keys_status ON activation_keys(status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS admin_keys');
      await db.execute('DROP TABLE IF EXISTS revoked_keys');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS activation_keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          serial_hash TEXT NOT NULL UNIQUE,
          key_full TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          device_id TEXT,
          created_at TEXT NOT NULL,
          activated_at TEXT,
          revoked_at TEXT,
          revoke_reason TEXT
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_activation_keys_serial ON activation_keys(serial_hash)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activation_keys_status ON activation_keys(status)');
    }

    if (oldVersion < 4) {
      final columns = await db.rawQuery("PRAGMA table_info(notes)");
      final hasEncryptedColumn = columns.any((col) => col['name'] == 'is_encrypted');

      if (!hasEncryptedColumn) {
        await db.execute('ALTER TABLE notes ADD COLUMN is_encrypted INTEGER DEFAULT 0');
        if (kDebugMode) {
          print('Colonne is_encrypted ajoutée avec succès.');
        }
      }
    }
  }

  Future<int> insertActivationKey(Map<String, dynamic> keyData) async {
    final db = await database;
    return await db.insert('activation_keys', keyData);
  }

  Future<List<Map<String, dynamic>>> getActivationKeysByStatus(String status) async {
    final db = await database;
    return await db.query(
      'activation_keys',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getActivationKeyBySerial(String serialHash) async {
    final db = await database;
    final results = await db.query(
      'activation_keys',
      where: 'serial_hash = ?',
      whereArgs: [serialHash],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateActivationKeyStatus({
    required String serialHash,
    required String status,
    String? deviceId,
    String? revokeReason,
  }) async {
    final db = await database;
    final data = <String, dynamic>{
      'status': status,
    };

    if (status == 'activated') {
      data['activated_at'] = DateTime.now().toIso8601String();
      if (deviceId != null) data['device_id'] = deviceId;
    } else if (status == 'revoked') {
      data['revoked_at'] = DateTime.now().toIso8601String();
      if (revokeReason != null) data['revoke_reason'] = revokeReason;
    }

    return await db.update(
      'activation_keys',
      data,
      where: 'serial_hash = ?',
      whereArgs: [serialHash],
    );
  }

  Future<int> deleteActivationKey(String serialHash) async {
    final db = await database;
    return await db.delete(
      'activation_keys',
      where: 'serial_hash = ?',
      whereArgs: [serialHash],
    );
  }

  Future<List<Map<String, dynamic>>> getNotesPaginated({
    required int page,
    required int pageSize,
    String? category,
    String? searchQuery,
    String orderBy = 'created_at DESC',
  }) async {
    try {
      final db = await database;
      final offset = page * pageSize;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (category != null && category.isNotEmpty) {
        whereClause = 'category = ?';
        whereArgs.add(category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isNotEmpty) {
          whereClause += ' AND ';
        }
        whereClause += '(title LIKE ? OR content LIKE ? OR tags LIKE ?)';
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final maps = await db.query(
        'notes',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
        limit: pageSize,
        offset: offset,
      );

      return maps;
    } catch (e) {
      print('Erreur lors de la récupération paginée: $e');
      return [];
    }
  }

  Future<int> getNotesCount({
    String? category,
    String? searchQuery,
  }) async {
    try {
      final db = await database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (category != null && category.isNotEmpty) {
        whereClause = 'category = ?';
        whereArgs.add(category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isNotEmpty) {
          whereClause += ' AND ';
        }
        whereClause += '(title LIKE ? OR content LIKE ? OR tags LIKE ?)';
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notes${whereClause.isNotEmpty ? ' WHERE $whereClause' : ''}',
        whereArgs.isNotEmpty ? whereArgs : null,
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Erreur lors du comptage des notes: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteNotesPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final db = await database;
      final offset = page * pageSize;

      final maps = await db.query(
        'notes',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
        limit: pageSize,
        offset: offset,
      );

      return maps;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des favoris: $e');
      }
      return [];
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> reset() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'notes_app.db');
    await deleteDatabase(path);
    _database = null;
  }

  Future<int> insertNote(Map<String, dynamic> noteData) async {
    final db = await database;
    return await db.insert('notes', noteData);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateNote(Map<String, dynamic> noteData) async {
    final db = await database;
    return await db.update(
      'notes',
      noteData,
      where: 'id = ?',
      whereArgs: [noteData['id']],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<List<Note>> getFavoriteNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'is_favorite = 1',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<bool> isActivated() async {
    final db = await database;
    final result = await db.query(
      'activation',
      where: 'is_activated = 1',
    );
    return result.isNotEmpty;
  }

  Future<void> activateKey(String key, String deviceId) async {
    final db = await database;
    await db.insert('activation', {
      'key_value': key,
      'is_activated': 1,
      'activated_at': DateTime.now().toIso8601String(),
      'device_id': deviceId,
    });
  }

  Future<void> deactivateApp() async {
    final db = await database;
    await db.delete('activation');
  }
}