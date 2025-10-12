import 'package:flutter/material.dart';
import 'package:gestionnaire_de_notes/widgets/recent_notes_widget.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../models/notebook.dart';
import '../models/humanitarian.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/quick_action_button.dart';
import '../services/pdf_service.dart';
import '../services/sharing_service.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';
import 'notebook_screen.dart';
import 'humanitarian_screen.dart';
import 'qr_scan_screen.dart';
import 'share_options_screen.dart';
import 'form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> _selectedNotes = {};
  bool _isSelectionMode = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotesProvider>().loadNotes(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.loadNextPage();
    }
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

  void _showBurgerMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Color(0xFF6366F1)),
              title: const Text('Scanner un QR Code'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScanScreen()),
                );
              },
            ),
            ListTile(
              leading: const Text('❤️', style: TextStyle(fontSize: 24)),
              title: const Text('Modèles humanitaires'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HumanitarianTemplatesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Color(0xFF6366F1)),
              title: const Text('Mes carnets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotebooksScreen()),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: const Color(0xFF6366F1),
                  ),
                  title: Text(themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre'),
                  onTap: () {
                    themeProvider.toggleTheme();
                    Navigator.pop(context);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF6366F1)),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
        body: SafeArea(
          child: Column(
            children: [
              if (!_isSelectionMode) _buildSearchAndFilters(),
              Expanded(
                child: Consumer<NotesProvider>(
                  builder: (context, notesProvider, _) {
                    if (notesProvider.isLoading && notesProvider.notes.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final notes = notesProvider.notes;

                    if (notes.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: [
                        const RecentNotesWidget(maxNotes: 5),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              controller: _scrollController,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: notes.length,
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
                                      if (note.humanitarianData != null) {
                                        final templateId = note.humanitarianData!['templateId'] as String?;
                                        if (templateId != null) {
                                          final template = Humanitarian.getTemplateById(templateId);
                                          if (template != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FormScreen(
                                                  humanitarian: template,
                                                  existingNote: note,
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                      }
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
                                    context.read<NotesProvider>().toggleFavorite(note.id!);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
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
          icon: const Icon(Icons.menu),
          onPressed: _showBurgerMenu,
          tooltip: 'Menu',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          custom.SearchBar(
            onSearchChanged: (query) {
              context.read<NotesProvider>().setSearchQuery(query);
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', Icons.grid_view, () {
                  context.read<NotesProvider>().setSortBy('dateDesc');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Favoris', Icons.star_outline, () {
                  context.read<NotesProvider>().setSortBy('favorites');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('A-Z', Icons.sort_by_alpha, () {
                  context.read<NotesProvider>().setSortBy('title');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Anciennes', Icons.access_time, () {
                  context.read<NotesProvider>().setSortBy('dateAsc');
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
            childAspectRatio: 1.0,
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
    return Flexible(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}