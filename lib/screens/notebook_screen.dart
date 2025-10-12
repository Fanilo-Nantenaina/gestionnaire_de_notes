import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notebook.dart';
import '../providers/notes_provider.dart';
import '../services/database_service.dart';

class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  Map<String, int> _noteCounts = {};
  bool _isLoadingCounts = true;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNoteCounts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true && _noteCounts.isEmpty) {
      _loadNoteCounts();
    }
  }

  Future<void> _loadNoteCounts() async {
    if (!mounted) return;

    setState(() => _isLoadingCounts = true);

    final notebooks = Notebook.getDefaultNotebooks();
    final Map<String, int> counts = {};

    try {
      final db = await _databaseService.database;
      final allNotesResult = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
      final totalNotes = allNotesResult.isNotEmpty
          ? (allNotesResult.first['count'] as int?) ?? 0
          : 0;

      for (final notebook in notebooks) {
        if (notebook.id == 'all') {
          counts[notebook.id] = totalNotes;
        } else {
          final categoryCount = await _countNotesForCategory(notebook.name);
          counts[notebook.id] = categoryCount;
        }
      }

      if (mounted) {
        setState(() {
          _noteCounts = counts;
          _isLoadingCounts = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  Future<int> _countNotesForCategory(String categoryName) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notes WHERE category = ?',
        [categoryName],
      );

      final count = result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
      return count;
    } catch (e) {
      return 0;
    }
  }

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
        actions: [
          IconButton(
            icon: _isLoadingCounts
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh),
            onPressed: _isLoadingCounts ? null : _loadNoteCounts,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await notesProvider.loadNotes(refresh: true);
              await _loadNoteCounts();
            },
            child: ListView(
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

                if (_isLoadingCounts && _noteCounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  const SizedBox(height: 24),

                  _buildSection(
                    context,
                    'Carnets généraux',
                    notebooks.where((nb) => !nb.isHumanitarian).toList(),
                    notesProvider,
                    isDark,
                  ),

                  const SizedBox(height: 32),

                  _buildSection(
                    context,
                    'Carnets humanitaires',
                    notebooks.where((nb) => nb.isHumanitarian).toList(),
                    notesProvider,
                    isDark,
                    isSpecial: true,
                  ),
                ],
              ],
            ),
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
            final notesCount = _noteCounts[notebook.id] ?? 0;

            return _buildNotebookCard(
              context,
              notebook,
              notesCount,
              isDark,
                  () async {
                notesProvider.setCategory(notebook.id);
                Navigator.pop(context);
              },
            );
          },
        ),
      ],
    );
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
      onTap: onTap,
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Container(
                      key: ValueKey(notesCount),
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