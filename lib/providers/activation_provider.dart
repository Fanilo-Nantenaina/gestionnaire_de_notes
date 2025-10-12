import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/activation_key_service.dart';

class ActivationProvider with ChangeNotifier {
  bool _isActivated = false;
  bool _isLoading = true;
  String? _activationKey;
  String? _deviceId;
  String? _adminPinHash;
  bool _isAdminAuthenticated = false;
  bool _mustChangeDefaultPin = false;
  bool _isBiometricEnabled = false;
  String _errorMessage = '';
  bool _hasSeenOnboarding = false;

  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  static const int _maxAttemptsBeforeDelay = 3;
  static const Duration _delayBetweenAttempts = Duration(seconds: 5);

  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  bool get isActivated => _isActivated;
  bool get isLoading => _isLoading;
  String? get activationKey => _activationKey;
  String? get deviceId => _deviceId;
  bool get isAdminAuthenticated => _isAdminAuthenticated;
  bool get mustChangeDefaultPin => _mustChangeDefaultPin;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String get errorMessage => _errorMessage;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  int get failedAttempts => _failedAttempts;
  DateTime? get lockoutEndTime => _lockoutEndTime;

  final DatabaseService _databaseService = DatabaseService.instance;
  late final ActivationKeyService _activationKeyService;
  SharedPreferences? _prefs;

  ActivationProvider() {
    _activationKeyService = ActivationKeyService(_databaseService);
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('[ActivationProvider] Starting initialization');
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();

      await _loadActivationStatus();
      await _loadAdminPin();
      await _loadLockoutStatus();
      await loadBiometricPreference();
      await _loadOnboardingStatus();

      debugPrint('[ActivationProvider] Initialization complete');
      debugPrint('[ActivationProvider] Is activated: $_isActivated');
      debugPrint('[ActivationProvider] Has seen onboarding: $_hasSeenOnboarding');
    } catch (e) {
      debugPrint('[ActivationProvider] Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadActivationStatus() async {
    try {
      _isActivated = _prefs!.getBool('is_activated') ?? false;
      _activationKey = _prefs!.getString('activation_key');
      _deviceId = _prefs!.getString('device_id');

      if (_isActivated) {
        final db = await _databaseService.database;
        final result = await db.query('activation', limit: 1);
        if (result.isEmpty) {
          _isActivated = false;
          await _prefs!.setBool('is_activated', false);
        }
      }
    } catch (e) {
      debugPrint('[ActivationProvider] Error loading activation status: $e');
      _isActivated = false;
    }
  }

  Future<void> _loadAdminPin() async {
    try {
      _adminPinHash = _prefs!.getString('admin_pin_hash');

      if (_adminPinHash == null) {
        await _saveHashedPin('0000');
        _mustChangeDefaultPin = true;
        await _prefs!.setBool('must_change_default_pin', true);
      } else {
        _mustChangeDefaultPin = _prefs!.getBool('must_change_default_pin') ?? false;
      }
    } catch (e) {
      debugPrint('[ActivationProvider] Error loading admin PIN: $e');
    }
  }

  Future<void> _loadLockoutStatus() async {
    try {
      _failedAttempts = _prefs!.getInt('failed_attempts') ?? 0;
      final lockoutString = _prefs!.getString('lockout_end_time');

      if (lockoutString != null) {
        _lockoutEndTime = DateTime.parse(lockoutString);

        if (DateTime.now().isAfter(_lockoutEndTime!)) {
          _lockoutEndTime = null;
          _failedAttempts = 0;
          await _prefs!.remove('lockout_end_time');
          await _prefs!.setInt('failed_attempts', 0);
        }
      }
    } catch (e) {
      debugPrint('[ActivationProvider] Error loading lockout status: $e');
      _failedAttempts = 0;
      _lockoutEndTime = null;
    }
  }

  Future<void> _loadOnboardingStatus() async {
    try {
      _hasSeenOnboarding = _prefs!.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      _hasSeenOnboarding = false;
    }
  }

  Future<bool> activate(String key, String deviceId) async {
    _errorMessage = '';
    notifyListeners();

    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('[ActivationProvider] Verifying activation key...');
      final verificationResult = await _activationKeyService.verifyActivationKey(key, deviceId);

      if (!verificationResult.success) {
        _errorMessage = verificationResult.message;
        debugPrint('[ActivationProvider] Key verification failed: ${verificationResult.message}');
        return false;
      }

      debugPrint('[ActivationProvider] Key verified successfully');

      final db = await _databaseService.database;
      await db.insert('activation', {
        'activation_key': key,
        'device_id': deviceId,
        'activated_at': DateTime.now().toIso8601String(),
      });

      await _prefs!.setBool('is_activated', true);
      await _prefs!.setString('activation_key', key);
      await _prefs!.setString('device_id', deviceId);

      _isActivated = true;
      _activationKey = key;
      _deviceId = deviceId;
      _errorMessage = '';

      debugPrint('[ActivationProvider] Activation successful');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'activation: ${e.toString()}';
      debugPrint('[ActivationProvider] Activation error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivate() async {
    try {
      final db = await _databaseService.database;
      await db.delete('activation');

      await _prefs!.remove('is_activated');
      await _prefs!.remove('activation_key');
      await _prefs!.remove('device_id');

      _isActivated = false;
      _activationKey = null;
      _deviceId = null;
      _isAdminAuthenticated = false;

      notifyListeners();
    } catch (e) {
      debugPrint('[ActivationProvider] Error during deactivation: $e');
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}FLUTTER_ONG_SALT_2025');
    return sha256.convert(bytes).toString();
  }

  Future<void> _saveHashedPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _prefs!.setString('admin_pin_hash', hashedPin);
    _adminPinHash = hashedPin;
  }

  Future<bool> _verifyPin(String pin) async {
    if (_adminPinHash == null) return false;
    final inputHash = _hashPin(pin);
    return inputHash == _adminPinHash;
  }

  Future<void> setAdminPin(String pin) async {
    await _saveHashedPin(pin);
    notifyListeners();
  }

  Future<bool> verifyAdminPin(String pin) async {
    try {
      if (!canAttemptLogin()) {
        final timeRemaining = getTimeUntilNextAttempt();
        if (timeRemaining != null) {
          throw Exception(
            'Trop de tentatives. Veuillez attendre ${timeRemaining.inSeconds} secondes.',
          );
        }
      }

      _loginAttempts++;
      _lastLoginAttempt = DateTime.now();

      if (_adminPinHash == null) {
        return false;
      }

      final hashedPin = _hashPin(pin);
      final isValid = hashedPin == _adminPinHash;

      if (isValid) {
        _loginAttempts = 0;
        _lastLoginAttempt = null;
        _failedAttempts = 0;
        _lockoutEndTime = null;
        await _prefs!.setInt('failed_attempts', 0);
        await _prefs!.remove('lockout_end_time');
        _isAdminAuthenticated = true;
        notifyListeners();
      } else {
        _failedAttempts++;
        await _prefs!.setInt('failed_attempts', _failedAttempts);

        if (_failedAttempts >= 5) {
          final lockoutMinutes = pow(2, (_failedAttempts - 5)).toInt();
          final lockoutDuration = Duration(minutes: lockoutMinutes);
          _lockoutEndTime = DateTime.now().add(lockoutDuration);
          await _prefs!.setString('lockout_end_time', _lockoutEndTime!.toIso8601String());
        }

        notifyListeners();
      }

      return isValid;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changeAdminPin(String oldPin, String newPin) async {
    try {
      final isOldPinValid = await _verifyPin(oldPin);
      if (!isOldPinValid) {
        return false;
      }

      await _saveHashedPin(newPin);

      if (_mustChangeDefaultPin && oldPin == '0000') {
        _mustChangeDefaultPin = false;
        await _prefs!.setBool('must_change_default_pin', false);
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool canAttemptLogin() {
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
      return false;
    }

    if (_lockoutEndTime != null && DateTime.now().isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failedAttempts = 0;
    }

    if (_loginAttempts < _maxAttemptsBeforeDelay) {
      return true;
    }

    if (_lastLoginAttempt == null) {
      return true;
    }

    final timeSinceLastAttempt = DateTime.now().difference(_lastLoginAttempt!);
    if (timeSinceLastAttempt >= _delayBetweenAttempts) {
      _loginAttempts = 0;
      return true;
    }

    return false;
  }

  Duration? getTimeUntilNextAttempt() {
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
      return _lockoutEndTime!.difference(DateTime.now());
    }

    if (_loginAttempts < _maxAttemptsBeforeDelay || _lastLoginAttempt == null) {
      return null;
    }

    final timeSinceLastAttempt = DateTime.now().difference(_lastLoginAttempt!);
    final timeRemaining = _delayBetweenAttempts - timeSinceLastAttempt;

    return timeRemaining.isNegative ? null : timeRemaining;
  }

  void logoutAdmin() {
    _isAdminAuthenticated = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      logoutAdmin();
      await deactivate();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadBiometricPreference() async {
    try {
      _isBiometricEnabled = _prefs!.getBool('biometric_enabled') ?? false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading biometric preferences: $e');
      }
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _prefs!.setBool('biometric_enabled', enabled);
      _isBiometricEnabled = enabled;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving biometric preferences: $e');
      }
    }
  }


  Future<void> markOnboardingAsSeen() async {
    try {
      await _prefs!.setBool('has_seen_onboarding', true);
      _hasSeenOnboarding = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving onboarding status: $e');
      }
    }
  }

  Future<void> completeOnboarding() async {
    await markOnboardingAsSeen();
  }

  Future<void> resetOnboarding() async {
    try {
      await _prefs!.remove('has_seen_onboarding');
      _hasSeenOnboarding = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting onboarding: $e');
      }
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}