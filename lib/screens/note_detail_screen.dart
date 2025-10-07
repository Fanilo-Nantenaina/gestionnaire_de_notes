import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/pdf_service.dart';
import 'share_options_screen.dart';
import '../models/notebook.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  final String? initialCategory;

  const NoteDetailScreen({super.key, this.note, this.initialCategory});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;

  bool _isFavorite = false;
  String _selectedCategory = 'Général';
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isCategoryLocked = false;

  bool get _isEditing => widget.note != null;

  static final _categories = Notebook.getDefaultNotebooks()
      .where((nb) => nb.id != 'all')
      .map((nb) => nb.name)
      .toList();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagController = TextEditingController();

    if (widget.note != null) {
      _isFavorite = widget.note!.isFavorite;
      final noteCategory = widget.note!.category;
      if (_categories.contains(noteCategory)) {
        _selectedCategory = noteCategory;
      } else {
        print('[v0] Invalid category detected: $noteCategory, using Général instead');
        _selectedCategory = 'Général';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final updatedNote = widget.note!.copyWith(category: 'Général');
          context.read<NotesProvider>().updateNote(updatedNote);
        });
      }
      _tags = List.from(widget.note!.tags);
    } else if (widget.initialCategory != null) {
      final notebook = Notebook.getNotebookById(widget.initialCategory!);
      if (notebook != null) {
        _selectedCategory = notebook.name;
        _isCategoryLocked = true;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      _showSnackBar('Titre ou contenu requis', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notesProvider = context.read<NotesProvider>();
      final now = DateTime.now();

      if (_isEditing) {
        final updatedNote = widget.note!.copyWith(
          title: title.isEmpty ? 'Sans titre' : title,
          content: content,
          isFavorite: _isFavorite,
          category: _selectedCategory,
          tags: _tags,
          updatedAt: now,
        );
        await notesProvider.updateNote(updatedNote);
        _showSnackBar('Note mise à jour');
      } else {
        final newNote = Note(
          title: title.isEmpty ? 'Sans titre' : title,
          content: content,
          isFavorite: _isFavorite,
          category: _selectedCategory,
          tags: _tags,
          createdAt: now,
          updatedAt: now,
        );
        await notesProvider.addNote(newNote);
        _showSnackBar('Note créée');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la note ?'),
        content: const Text('Cette action est irréversible.'),
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
      setState(() => _isLoading = true);
      try {
        await context.read<NotesProvider>().deleteNote(widget.note!.id!);
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Note supprimée');
        }
      } catch (e) {
        _showSnackBar('Erreur: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (!_isEditing) return;
    setState(() => _isLoading = true);
    try {
      await PdfService.exportSingleNote(widget.note!);
      _showSnackBar('Export réussi');
    } catch (e) {
      _showSnackBar('Erreur export: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.note == null ? 'Nouvelle note' : 'Modifier'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (widget.note != null) ...[
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShareOptionsScreen(note: widget.note!),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteNote,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: _isLoading ? null : _saveNote,
            icon: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      suffixIcon: _isCategoryLocked
                          ? const Icon(Icons.lock_outline, size: 20)
                          : null,
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: _isCategoryLocked
                        ? null
                        : (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                      icon: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite ? Colors.amber : Colors.grey,
                        size: 28,
                      ),
                    ),
                    Text(
                      'Favori',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFavorite ? Colors.amber : Colors.grey,
                        fontWeight: _isFavorite ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: 'Ajouter un tag',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                suffixIcon: IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ),
              //onSubmitted: (_) => _addTag(),
            ),

            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _removeTag(tag),
                  deleteIconColor: Colors.grey[600],
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],

            const SizedBox(height: 20),

            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              textAlignVertical: TextAlignVertical.top,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveNote,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Mettre à jour' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
