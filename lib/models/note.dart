import 'dart:convert';
import '../services/encryption_service.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool isFavorite;
  final Map<String, dynamic>? humanitarianData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEncrypted;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.isFavorite = false,
    this.humanitarianData,
    required this.createdAt,
    required this.updatedAt,
    this.isEncrypted = false,
  });

  Future<Note> encrypt() async {
    if (isEncrypted) return this;

    final encryptionService = EncryptionService();

    return Note(
      id: id,
      title: encryptionService.encryptText(title),
      content: encryptionService.encryptText(content),
      category: category,
      tags: tags,
      isFavorite: isFavorite,
      humanitarianData: humanitarianData != null
          ? jsonDecode(encryptionService.decryptText(encryptionService.encryptText(jsonEncode(humanitarianData))))
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isEncrypted: true,
    );
  }

  Future<Note> decrypt() async {
    if (!isEncrypted) return this;

    final encryptionService = EncryptionService();

    return Note(
      id: id,
      title: encryptionService.decryptText(title),
      content: encryptionService.decryptText(content),
      category: category,
      tags: tags,
      isFavorite: isFavorite,
      humanitarianData: humanitarianData != null
          ? jsonDecode(encryptionService.decryptText(jsonEncode(humanitarianData)))
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isEncrypted: false,
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? category,
    Map<String, dynamic>? humanitarianData,
    bool? isEncrypted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      humanitarianData: humanitarianData ?? this.humanitarianData,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags.join(','),
      'is_favorite': isFavorite ? 1 : 0,
      'humanitarian_data': humanitarianData != null ? jsonEncode(humanitarianData) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_encrypted': isEncrypted ? 1 : 0,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      tags: json['tags'] != null && json['tags'].isNotEmpty
          ? (json['tags'] as String).split(',')
          : [],
      isFavorite: json['is_favorite'] == 1,
      humanitarianData: json['humanitarian_data'] != null
          ? jsonDecode(json['humanitarian_data'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isEncrypted: json['is_encrypted'] == 1,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes <= 1) {
          return 'À l\'instant';
        }
        return '${diff.inMinutes}min';
      }
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}sem';
    } else {
      return '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
    }
  }

  String get excerpt {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}