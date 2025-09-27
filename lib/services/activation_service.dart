class ActivationService {
  static const List<String> _validKeys = [
    'DEMO-2024-NOTES-001',
    'DEMO-2024-NOTES-002',
    'DEMO-2024-NOTES-003',
    'TEST-KEY-FLUTTER-01',
    'MVVM-ARCH-KEY-2024',
  ];

  bool validateKey(String key) {
    if (key.isEmpty || key.length < 10) return false;

    if (_validKeys.contains(key.toUpperCase())) {
      return true;
    }

    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{3}$');
    return regex.hasMatch(key.toUpperCase());
  }

  List<String> getDemoKeys() => _validKeys;
}
