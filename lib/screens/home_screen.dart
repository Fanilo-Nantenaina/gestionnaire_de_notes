import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/quick_action_button.dart';
import '../widgets/help_tooltip.dart';
import '../services/pdf_service.dart';
import '../services/sharing_service.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';
import 'notebook_screen.dart';
import 'humanitarian_screen.dart';
import 'qr_scan_screen.dart';
import 'share_options_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _selectedNotes = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotesProvider>().loadNotes();
      }
    });
  }

  void _showAddNoteScreen() {
    final notesProvider = context.read<NotesProvider>();
    final selectedCategory = notesProvider.selectedCategory;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          initialCategory: selectedCategory != 'all' ? selectedCategory : null,
        ),
      ),
    );
  }

  void _enterSelectionMode(int noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedNotes.add(noteId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotes.clear();
    });
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNotes.contains(noteId)) {
        _selectedNotes.remove(noteId);
        if (_selectedNotes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotes.add(noteId);
      }
    });
  }

  Future<void> _exportSelectedNotes() async {
    if (mounted) {
      final notesProvider = context.read<NotesProvider>();
      final selectedNotes = notesProvider.getSelectedNotes(_selectedNotes.toList());

      if (selectedNotes.isNotEmpty) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Export en cours...'),
                ],
              ),
              backgroundColor: Color(0xFF6366F1),
            ),
          );

          final filePath = await PdfService.exportNotesToPdf(
            selectedNotes,
            title: selectedNotes.length == 1
                ? selectedNotes.first.title
                : 'Notes sélectionnées (${selectedNotes.length})',
          );

          _exitSelectionMode();

          if (mounted && filePath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedNotes.length} note(s) exportée(s)!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        } catch (e) {
          _exitSelectionMode();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _deleteSelectedNotes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Supprimer ${_selectedNotes.length} note(s) ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notesProvider = context.read<NotesProvider>();
      for (final noteId in _selectedNotes) {
        await notesProvider.deleteNote(noteId);
      }
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            if (!_isSelectionMode) _buildSearchAndFilters(),
            Expanded(
              child: Consumer<NotesProvider>(
                builder: (context, notesProvider, _) {
                  if (notesProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final notes = notesProvider.notes;

                  if (notes.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildNotesGrid(notes);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode ? null : _buildFAB(),
        bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
          tooltip: 'Annuler la sélection',
        ),
        title: Text('${_selectedNotes.length} sélectionnée(s)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final notesProvider = context.read<NotesProvider>();
              final selectedNotes = notesProvider.getSelectedNotes(_selectedNotes.toList());
              if (selectedNotes.length == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShareOptionsScreen(note: selectedNotes.first),
                  ),
                );
              } else {
                await SharingService.shareNotesAsJson(selectedNotes);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedNotes.length} notes exportées'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            tooltip: 'Partager les notes',
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              final notesProvider = context.read<NotesProvider>();
              setState(() {
                if (_selectedNotes.length == notesProvider.notes.length) {
                  _selectedNotes.clear();
                } else {
                  _selectedNotes.clear();
                  _selectedNotes.addAll(
                    notesProvider.notes.map((note) => note.id!).toList(),
                  );
                }
              });
            },
            tooltip: 'Tout sélectionner',
          ),
        ],
      );
    }

    return AppBar(
      title: Consumer<NotesProvider>(
        builder: (context, provider, _) {
          final category = provider.selectedCategory;
          final notebook = Notebook.getNotebookById(category);

          return Row(
            children: [
              if (notebook != null && category != 'all') ...[
                Text(
                  notebook.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  notebook?.name ?? 'Notes',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanScreen()),
          ),
          tooltip: 'Scanner un QR Code',
        ),
        IconButton(
          icon: const Text('❤️', style: TextStyle(fontSize: 22)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HumanitarianTemplatesScreen()),
          ),
          tooltip: 'Modèles humanitaires',
        ),
        IconButton(
          icon: const Icon(Icons.folder_outlined, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotebooksScreen()),
          ),
          tooltip: 'Mes carnets',
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 26,
              ),
              onPressed: themeProvider.toggleTheme,
              tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          tooltip: 'Paramètres',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          custom.SearchBar(
            onSearchChanged: (query) {
              context.read<NotesProvider>().searchNotes(query);
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', Icons.grid_view, () {
                  context.read<NotesProvider>().setSortType(SortType.dateDesc);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Favoris', Icons.star_outline, () {
                  context.read<NotesProvider>().setSortType(SortType.favorites);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('A-Z', Icons.sort_by_alpha, () {
                  context.read<NotesProvider>().setSortType(SortType.title);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Anciennes', Icons.access_time, () {
                  context.read<NotesProvider>().setSortType(SortType.dateAsc);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: MasonryGridView.builder(
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: notes.length,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            isSelected: _selectedNotes.contains(note.id),
            isSelectionMode: _isSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                _toggleNoteSelection(note.id!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteDetailScreen(note: note),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _enterSelectionMode(note.id!);
              }
            },
            onFavoriteToggle: () {
              context.read<NotesProvider>().toggleFavorite(note);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.note_add_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenue!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez à créer vos notes',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              QuickActionButton(
                icon: Icons.note_add,
                label: 'Nouvelle note',
                description: 'Créer une note simple',
                color: const Color(0xFF6366F1),
                onTap: _showAddNoteScreen,
              ),
              QuickActionButton(
                icon: Icons.favorite,
                label: 'Modèles',
                description: 'Fiches humanitaires',
                color: const Color(0xFFEF4444),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HumanitarianTemplatesScreen(),
                  ),
                ),
              ),
              QuickActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scanner',
                description: 'Recevoir une note',
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScanScreen()),
                ),
              ),
              QuickActionButton(
                icon: Icons.folder,
                label: 'Carnets',
                description: 'Organiser vos notes',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotebooksScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: const Color(0xFF6366F1),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Astuce',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Maintenez appuyé sur une note pour la sélectionner et accéder aux options de partage et d\'export.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddNoteScreen,
      icon: const Icon(Icons.add, size: 26),
      label: const Text(
        'Nouvelle note',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share,
                label: 'Partager',
                onPressed: () async {
                  final notesProvider = context.read<NotesProvider>();
                  final selectedNotes = notesProvider.getSelectedNotes(_selectedNotes.toList());
                  if (selectedNotes.length == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShareOptionsScreen(note: selectedNotes.first),
                      ),
                    );
                  } else {
                    await SharingService.shareNotesAsJson(selectedNotes);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${selectedNotes.length} notes exportées'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                onPressed: _exportSelectedNotes,
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Supprimer',
                onPressed: _deleteSelectedNotes,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isDestructive ? Colors.red : const Color(0xFF6366F1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
