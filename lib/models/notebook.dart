class Notebook {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String description;
  final bool isHumanitarian;

  Notebook({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.isHumanitarian = false,
  });

  static List<Notebook> getDefaultNotebooks() {
    return [
      Notebook(
        id: 'all',
        name: 'Toutes les notes',
        icon: '📋',
        color: '6366F1',
        description: 'Voir toutes vos notes',
      ),
      Notebook(
        id: 'general',
        name: 'Général',
        icon: '📝',
        color: '6366F1',
        description: 'Notes générales',
      ),
      Notebook(
        id: 'work',
        name: 'Travail',
        icon: '💼',
        color: '3B82F6',
        description: 'Notes professionnelles',
      ),
      Notebook(
        id: 'personal',
        name: 'Personnel',
        icon: '🏠',
        color: '8B5CF6',
        description: 'Notes personnelles',
      ),
      Notebook(
        id: 'humanitarian',
        name: 'Humanitaire',
        icon: '❤️',
        color: 'EF4444',
        description: 'Fiches humanitaires et aide',
        isHumanitarian: true,
      ),
      Notebook(
        id: 'health',
        name: 'Santé',
        icon: '🏥',
        color: '10B981',
        description: 'Notes médicales et santé',
      ),
      Notebook(
        id: 'finance',
        name: 'Finance',
        icon: '💰',
        color: 'F59E0B',
        description: 'Budget et finances',
      ),
      Notebook(
        id: 'education',
        name: 'Éducation',
        icon: '📚',
        color: '06B6D4',
        description: 'Cours et apprentissage',
      ),
      Notebook(
        id: 'shopping',
        name: 'Courses',
        icon: '🛒',
        color: 'EC4899',
        description: 'Listes de courses',
      ),
      Notebook(
        id: 'travel',
        name: 'Voyages',
        icon: '✈️',
        color: '14B8A6',
        description: 'Plans de voyage',
      ),
    ];
  }

  static Notebook? getNotebookById(String id) {
    try {
      return getDefaultNotebooks().firstWhere((nb) => nb.id == id);
    } catch (e) {
      return null;
    }
  }

  static String getCategoryDisplayName(String category) {
    final notebook = getNotebookById(category.toLowerCase());
    return notebook?.name ?? category;
  }

  static String getCategoryIcon(String category) {
    final notebook = getNotebookById(category.toLowerCase());
    return notebook?.icon ?? '📝';
  }
}
