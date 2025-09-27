import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

enum SortType { dateDesc, dateAsc, title, favorites }

class NotesProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  SortType _sortType = SortType.dateDesc;
  String _selectedCategory = 'All';
  bool _isLoading = false;

  List<Note> get notes => _filteredNotes;
  String get searchQuery => _searchQuery;
  SortType get sortType => _sortType;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final cats = _notes.map((note) => note.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _db.getAllNotes();
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Erreur lors du chargement des notes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    try {
      final id = await _db.insertNote(note);
      final newNote = note.copyWith(id: id);
      _notes.insert(0, newNote);
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _db.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        _applyFiltersAndSort();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _db.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
    }
  }

  Future<void> toggleFavorite(Note note) async {
    final updatedNote = note.copyWith(
      isFavorite: !note.isFavorite,
      updatedAt: DateTime.now(),
    );
    await updateNote(updatedNote);
  }

  void searchNotes(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortType(SortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    var filtered = List<Note>.from(_notes);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered.where((note) => note.category == _selectedCategory).toList();
    }

    switch (_sortType) {
      case SortType.dateDesc:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortType.dateAsc:
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortType.title:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortType.favorites:
        filtered.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }

    _filteredNotes = filtered;
  }

  List<Note> getSelectedNotes(List<int> selectedIds) {
    return _notes.where((note) => selectedIds.contains(note.id)).toList();
  }
}
