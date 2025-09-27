import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/pdf_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;

  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;

  bool _isFavorite = false;
  String _selectedCategory = 'General';
  List<String> _tags = [];
  bool _isLoading = false;

  bool get _isEditing => widget.note != null;

  static const _categories = [
    'Général', 'Travail', 'Personel', 'Idées', 'Shopping',
    'Voyages', 'Santé', 'Finance', 'Education', 'Projets'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagController = TextEditingController();

    if (widget.note != null) {
      _isFavorite = widget.note!.isFavorite;
      _selectedCategory = widget.note!.category;
      _tags = List.from(widget.note!.tags);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier' : 'Nouvelle note'),
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            IconButton(
              onPressed: _isLoading ? null : _exportToPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              onPressed: _isLoading ? null : _deleteNote,
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(foregroundColor: Colors.red),
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
              label: Text(_isEditing ? 'Modifier' : 'Créer'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
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

            const SizedBox(height: 24),

            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: 'Ajouter un tag',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),

            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _removeTag(tag),
                  deleteIconColor: Colors.grey[600],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],

            const SizedBox(height: 24),

            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              textAlignVertical: TextAlignVertical.top,
            ),
          ],
        ),
      ),
    );
  }
}