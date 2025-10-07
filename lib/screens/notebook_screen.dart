import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notebook.dart';
import '../providers/notes_provider.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notebooks = Notebook.getDefaultNotebooks();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Carnets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Organisez vos notes par carnets',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Section: Carnets généraux
              _buildSection(
                context,
                'Carnets généraux',
                notebooks.where((nb) => !nb.isHumanitarian).toList(),
                notesProvider,
                isDark,
              ),

              const SizedBox(height: 32),

              // Section: Carnets humanitaires
              _buildSection(
                context,
                'Carnets humanitaires',
                notebooks.where((nb) => nb.isHumanitarian).toList(),
                notesProvider,
                isDark,
                isSpecial: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<Notebook> notebooks,
      NotesProvider notesProvider,
      bool isDark, {
        bool isSpecial = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              if (isSpecial)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '❤️',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              if (isSpecial) const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
          ),
          itemCount: notebooks.length,
          itemBuilder: (context, index) {
            final notebook = notebooks[index];
            final notesCount = _getNotesCountForCategory(
              notesProvider,
              notebook.id,
            );

            return _buildNotebookCard(
              context,
              notebook,
              notesCount,
              isDark,
                  () {
                notesProvider.setCategory(notebook.id);
                Navigator.pop(context);
              },
            );
          },
        ),
      ],
    );
  }

  int _getNotesCountForCategory(NotesProvider provider, String categoryId) {
    if (categoryId == 'all') {
      return provider.notes.length;
    }
    final notebook = Notebook.getNotebookById(categoryId);
    if (notebook == null) return 0;

    return provider.notes
        .where((note) => note.category == notebook.name)
        .length;
  }

  Widget _buildNotebookCard(
      BuildContext context,
      Notebook notebook,
      int notesCount,
      bool isDark,
      VoidCallback onTap,
      ) {
    final color = Color(int.parse('FF${notebook.color}', radix: 16));

    return InkWell(
      onTap: () {
        final notesProvider = context.read<NotesProvider>();
        notesProvider.setCategory(notebook.id);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        notebook.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$notesCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notebook.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notebook.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
