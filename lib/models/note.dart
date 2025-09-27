class Note {
  final int? id;
  final String title;
  final String content;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String category;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.category = 'General',
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? category,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags.join(','),
      'category': category,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      tags: map['tags'] != null && map['tags'].isNotEmpty
          ? map['tags'].split(',')
          : [],
      category: map['category'] ?? 'General',
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
