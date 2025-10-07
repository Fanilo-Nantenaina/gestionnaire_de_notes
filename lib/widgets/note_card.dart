import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/notebook.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteToggle;
  final bool isSelected;
  final bool isSelectionMode;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteToggle,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryIcon = Notebook.getCategoryIcon(note.category);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.2)
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        categoryIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      note.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: note.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                      if (!isSelectionMode)
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            note.isFavorite
                                ? Icons.star
                                : Icons.star_outline,
                            size: 20,
                            color: note.isFavorite
                                ? const Color(0xFFF59E0B)
                                : (isDark ? Colors.grey[600] : Colors.grey[400]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
