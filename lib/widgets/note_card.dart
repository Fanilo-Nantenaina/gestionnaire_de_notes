import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isSelected ? null : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.2)
                : (isDark ? Colors.transparent : Colors.black.withOpacity(0.04)),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(context, isDark),
                const SizedBox(height: 12),
                _buildContent(isDark),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildTags(isDark),
                ],
                const SizedBox(height: 12),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        _buildCategoryIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getCategoryColor(),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onFavoriteToggle != null)
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: IconButton(
              icon: Icon(
                note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: note.isFavorite ? const Color(0xFFFBBF24) : (isDark ? Colors.grey[600] : Colors.grey[400]),
                size: 22,
              ),
              onPressed: onFavoriteToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(),
            _getCategoryColor().withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getCategoryIcon(),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Text(
      note.content,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
        height: 1.6,
        letterSpacing: 0.1,
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(bool isDark) {
    final displayTags = note.tags.take(3).toList();
    final hasMore = note.tags.length > 3;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTags.map((tag) => _buildTag(tag, isDark)),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${note.tags.length - 3}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6366F1),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(note.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon() {
    switch (note.category) {
      case 'Travail':
        return Icons.work_rounded;
      case 'Personnel':
        return Icons.person_rounded;
      case 'Humanitaire':
        return Icons.favorite_rounded;
      case 'Santé':
        return Icons.health_and_safety_rounded;
      case 'Finance':
        return Icons.account_balance_wallet_rounded;
      case 'Voyage':
        return Icons.flight_takeoff_rounded;
      case 'Éducation':
        return Icons.school_rounded;
      case 'Projets':
        return Icons.folder_rounded;
      case 'Idées':
        return Icons.lightbulb_rounded;
      default:
        return Icons.note_rounded;
    }
  }

  Color _getCategoryColor() {
    switch (note.category) {
      case 'Travail':
        return const Color(0xFF6366F1);
      case 'Personnel':
        return const Color(0xFF10B981);
      case 'Humanitaire':
        return const Color(0xFFEF4444);
      case 'Santé':
        return const Color(0xFFF59E0B);
      case 'Finance':
        return const Color(0xFF8B5CF6);
      case 'Voyage':
        return const Color(0xFF06B6D4);
      case 'Éducation':
        return const Color(0xFFEC4899);
      case 'Projets':
        return const Color(0xFF14B8A6);
      case 'Idées':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a ${weeks}sem';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}