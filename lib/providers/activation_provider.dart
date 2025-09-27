import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/database_service.dart';
import '../services/activation_service.dart';

class ActivationProvider with ChangeNotifier {
  static const String _onboardingKey = 'has_seen_onboarding';

  bool _isActivated = false;
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  String _errorMessage = '';

  bool get isActivated => _isActivated;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get errorMessage => _errorMessage;

  final DatabaseService _db = DatabaseService();
  final ActivationService _activationService = ActivationService();

  Future<void> checkActivationStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
      _isActivated = await _db.isActivated();
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'activation: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<bool> activateWithKey(String key) async {
    _errorMessage = '';
    notifyListeners();

    try {
      if (!_activationService.validateKey(key)) {
        _errorMessage = 'Clé d\'activation invalide';
        notifyListeners();
        return false;
      }

      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } catch (e) {
        deviceId = 'unknown_device';
      }

      await _db.activateKey(key, deviceId);

      _isActivated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'activation: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _db.deactivateApp();
      _isActivated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }
}
