import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../services/database_service.dart';

class NotesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'date';

  final Map<int, Note> _notesCache = {};
  DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreNotes = true;
  int _totalNotesCount = 0;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get hasMoreNotes => _hasMoreNotes;
  int get totalNotesCount => _totalNotesCount;
  int get currentPage => _currentPage;

  NotesProvider() {
    loadNotes();
  }

  String? _getCategoryNameForQuery(String categoryId) {
    if (categoryId == 'all' || categoryId.isEmpty) {
      return null;
    }

    final notebook = Notebook.getNotebookById(categoryId);
    return notebook?.name;
  }

  Future<void> loadNotes({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 0;
      _notes.clear();
      _hasMoreNotes = true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final categoryName = _getCategoryNameForQuery(_selectedCategory);

      _totalNotesCount = await _databaseService.getNotesCount(
        category: categoryName,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final maps = await _databaseService.getNotesPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        category: categoryName,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        orderBy: _getSortOrder(),
      );

      final newNotes = maps.map((map) => Note.fromJson(map)).toList();

      if (refresh) {
        _notes = newNotes;
      } else {
        _notes.addAll(newNotes);
      }

      for (final note in newNotes) {
        if (note.id != null) {
          _notesCache[note.id!] = note;
        }
      }
      _lastCacheUpdate = DateTime.now();
      _hasMoreNotes = _notes.length < _totalNotesCount;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading notes: $e');
        print('Stack trace: $stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMoreNotes || _isLoading) return;

    _currentPage++;
    await loadNotes();
  }

  Future<Note?> getNote(int id) async {
    if (_isCacheValid() && _notesCache.containsKey(id)) {
      return _notesCache[id];
    }

    try {
      final map = await _databaseService.getNoteById(id);
      if (map != null) {
        final note = Note.fromJson(map as Map<String, dynamic>);
        _notesCache[id] = note;
        _lastCacheUpdate = DateTime.now();
        return note;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotesProvider] Error getting note: $e');
      }
    }

    return null;
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  void _invalidateCache() {
    _notesCache.clear();
    _lastCacheUpdate = null;
  }

  String _getSortOrder() {
    switch (_sortBy) {
      case 'title':
        return 'title ASC';
      case 'favorite':
      case 'favorites':
        return 'is_favorite DESC, created_at DESC';
      case 'dateAsc':
        return 'created_at ASC';
      case 'date':
      case 'dateDesc':
      default:
        return 'created_at DESC';
    }
  }

  Future<void> addNote(Note note) async {
    try {

      final id = await _databaseService.insertNote(note.toJson());
      final newNote = note.copyWith(id: id);

      _notes.insert(0, newNote);
      _notesCache[id] = newNote;
      _totalNotesCount++;

      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error adding note: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _databaseService.updateNote(note.toJson());

      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      }

      if (note.id != null) {
        _notesCache[note.id!] = note;
      }

      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error updating note: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<bool> deleteNote(int id) async {
    try {
      await _databaseService.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);

      _notesCache.remove(id);
      _totalNotesCount--;

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting note: $e');
      }
      return false;
    }
  }

  Future<bool> deleteMultipleNotes(List<int> ids) async {
    try {
      for (final id in ids) {
        await _databaseService.deleteNote(id);
        _notesCache.remove(id);
      }

      _notes.removeWhere((note) => ids.contains(note.id));
      _totalNotesCount -= ids.length;

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting multiple notes: $e');
      }
      return false;
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadNotes(refresh: true);
    }
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadNotes(refresh: true);
    }
  }

  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      loadNotes(refresh: true);
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      final note = _notes.firstWhere((n) => n.id == id);
      final updatedNote = note.copyWith(
        isFavorite: !note.isFavorite,
        updatedAt: DateTime.now(),
      );

      await updateNote(updatedNote);
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
    }
  }

  Future<void> prefetchNextPage() async {
    if (!_hasMoreNotes || _isLoading) return;

    final categoryName = _getCategoryNameForQuery(_selectedCategory);
    final nextPage = _currentPage + 1;

    final maps = await _databaseService.getNotesPaginated(
      page: nextPage,
      pageSize: _pageSize,
      category: categoryName,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      orderBy: _getSortOrder(),
    );

    for (final map in maps) {
      final note = Note.fromJson(map);
      if (note.id != null) {
        _notesCache[note.id!] = note;
      }
    }
  }

  Future<List<Note>> getRecentNotes({int limit = 5}) async {
    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        orderBy: 'updated_at DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
    } catch (e) {
      debugPrint('Error getting recent notes: $e');
      return [];
    }
  }

  void cleanOldCache() {
    if (!_isCacheValid()) {
      _invalidateCache();
    }
  }

  List<Note> getSelectedNotes(List<int> selectedIds) {
    return _notes.where((note) => selectedIds.contains(note.id)).toList();
  }
}