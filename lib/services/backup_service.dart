import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import 'database_service.dart';
import 'encryption_service.dart';

class BackupService {
  final DatabaseService _databaseService = DatabaseService.instance;
  final EncryptionService _encryptionService = EncryptionService();

  Future<String?> createBackup({bool includeEncryptionKey = false}) async {
    try {
      final db = await _databaseService.database;
      final noteMaps = await db.query('notes', orderBy: 'created_at DESC');
      final notes = noteMaps.map((map) => Note.fromJson(map)).toList();

      final backupData = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes_count': notes.length,
        'notes': notes.map((note) => note.toJson()).toList(),
      };

      if (includeEncryptionKey) {
        final encryptionKey = await _encryptionService.exportKey();
        if (encryptionKey != null) {
          backupData['encryption_key'] = encryptionKey;
        }
      }

      final jsonString = jsonEncode(backupData);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du backup: $e');
      }
      return null;
    }
  }

  Future<bool> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final version = backupData['version'] as String?;
      if (version != '1.0') {
        return false;
      }

      if (backupData.containsKey('encryption_key')) {
        final encryptionKey = backupData['encryption_key'] as String;
        await _encryptionService.importKey(encryptionKey);
      }

      final notesList = backupData['notes'] as List<dynamic>;
      final db = await _databaseService.database;

      await db.transaction((txn) async {
        for (final noteData in notesList) {
          final noteMap = noteData as Map<String, dynamic>;
          noteMap.remove('id');
          await txn.insert('notes', noteMap);
        }
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la restauration du backup: $e');
      }
      return false;
    }
  }

  Future<bool> shareBackup({bool includeEncryptionKey = false}) async {
    try {
      final backupPath = await createBackup(includeEncryptionKey: includeEncryptionKey);
      if (backupPath == null) return false;

      final result = await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'Backup Notes - ${DateTime.now().toString().split(' ')[0]}',
        text: 'Backup de vos notes créé le ${DateTime.now().toString().split(' ')[0]}',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  Future<void> createAutoBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final backupPath = await createBackup(includeEncryptionKey: true);
      if (backupPath == null) return;

      final backupFile = File(backupPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final autoBackupPath = '${backupDir.path}/auto_backup_$timestamp.json';
      await backupFile.copy(autoBackupPath);

      await _cleanOldBackups(backupDir);

    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du backup automatique: $e');
      }
    }
  }

  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();
      final backupFiles = files.whereType<File>().toList();

      backupFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      if (backupFiles.length > 5) {
        for (int i = 5; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du nettoyage des backups: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> listAutoBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/auto_backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backupFiles = files.whereType<File>().toList();

      final backups = <Map<String, dynamic>>[];
      for (final file in backupFiles) {
        final stat = await file.stat();
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        backups.add({
          'path': file.path,
          'created_at': data['created_at'],
          'notes_count': data['notes_count'],
          'size': stat.size,
          'modified': stat.modified,
        });
      }

      backups.sort((a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

      return backups;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la liste des backups: $e');
      }
      return [];
    }
  }

  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du backup: $e');
      }
      return false;
    }
  }
}