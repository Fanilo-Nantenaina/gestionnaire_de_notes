import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../screens/note_detail_screen.dart';

class RecentNotesWidget extends StatelessWidget {
  final int maxNotes;

  const RecentNotesWidget({
    super.key,
    this.maxNotes = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.searchQuery.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Note>>(
          future: notesProvider.getRecentNotes(limit: maxNotes),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final recentNotes = snapshot.data!;

            if (recentNotes.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notes récentes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentNotes.length,
                    itemBuilder: (context, index) {
                      final note = recentNotes[index];
                      return _buildRecentNoteCard(context, note);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentNoteCard(BuildContext context, Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(note.category);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteDetailScreen(note: note),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                categoryColor.withOpacity(0.15),
                categoryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(note.category),
                      size: 16,
                      color: categoryColor,
                    ),
                  ),
                  const Spacer(),
                  if (note.isFavorite)
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Travail':
        return const Color(0xFF6366F1);
      case 'Personnel':
        return const Color(0xFF8B5CF6);
      case 'Humanitaire':
        return const Color(0xFFEF4444);
      case 'Santé':
        return const Color(0xFF10B981);
      case 'Finance':
        return const Color(0xFFF59E0B);
      case 'Éducation':
        return const Color(0xFF3B82F6);
      case 'Courses':
        return const Color(0xFFEC4899);
      case 'Voyages':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Travail':
        return Icons.work_outline;
      case 'Personnel':
        return Icons.person_outline;
      case 'Humanitaire':
        return Icons.favorite_outline;
      case 'Santé':
        return Icons.health_and_safety_outlined;
      case 'Finance':
        return Icons.attach_money;
      case 'Éducation':
        return Icons.school_outlined;
      case 'Courses':
        return Icons.shopping_cart_outlined;
      case 'Voyages':
        return Icons.flight_outlined;
      default:
        return Icons.note_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}