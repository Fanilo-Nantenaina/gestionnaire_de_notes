import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';

class SharingService {
  static String encodeNote(Note note) {
    final noteData = {
      'title': note.title,
      'content': note.content,
      'category': note.category,
      'tags': note.tags,
      'isFavorite': note.isFavorite,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
    };
    return jsonEncode(noteData);
  }

  static Note? decodeNote(String data) {
    try {
      final Map<String, dynamic> noteData = jsonDecode(data);
      return Note(
        title: noteData['title'] ?? '',
        content: noteData['content'] ?? '',
        category: noteData['category'] ?? 'general',
        tags: List<String>.from(noteData['tags'] ?? []),
        isFavorite: noteData['isFavorite'] ?? false,
        createdAt: DateTime.parse(noteData['createdAt']),
        updatedAt: DateTime.parse(noteData['updatedAt']),
      );
    } catch (e) {
      debugPrint('Erreur lors du décodage de la note: $e');
      return null;
    }
  }

  static String encodeMultipleNotes(List<Note> notes) {
    final notesData = notes.map((note) {
      return {
        'title': note.title,
        'content': note.content,
        'category': note.category,
        'tags': note.tags,
        'isFavorite': note.isFavorite,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
      };
    }).toList();

    return jsonEncode({
      'version': '1.0',
      'count': notes.length,
      'notes': notesData,
    });
  }

  static List<Note>? decodeMultipleNotes(String data) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(data);
      final List<dynamic> notesData = jsonData['notes'] ?? [];

      return notesData.map((noteData) {
        return Note(
          title: noteData['title'] ?? '',
          content: noteData['content'] ?? '',
          category: noteData['category'] ?? 'general',
          tags: List<String>.from(noteData['tags'] ?? []),
          isFavorite: noteData['isFavorite'] ?? false,
          createdAt: DateTime.parse(noteData['createdAt']),
          updatedAt: DateTime.parse(noteData['updatedAt']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors du décodage des notes: $e');
      return null;
    }
  }

  static Future<void> shareNoteAsText(Note note) async {
    final text = '''
${note.title}

${note.content}

---
Catégorie: ${note.category}
Tags: ${note.tags.join(', ')}
Date: ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}
''';

    await Share.share(text, subject: note.title);
  }

  static Future<void> shareNotesAsJson(List<Note> notes) async {
    final jsonData = encodeMultipleNotes(notes);
    await Share.share(
      jsonData,
      subject: 'Export de ${notes.length} note(s)',
    );
  }
}
