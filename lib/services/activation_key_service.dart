import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'crypto_service.dart';

class ActivationKeyService {
  final DatabaseService _databaseService;

  ActivationKeyService(this._databaseService);

  Future<ActivationResult> verifyActivationKey(String key, String deviceId) async {
    try {
      if (key.isEmpty || deviceId.isEmpty) {
        return ActivationResult(
          success: false,
          message: 'Clé ou ID appareil invalide',
        );
      }

      if (!CryptoService.verifyKey(key)) {
        return ActivationResult(
          success: false,
          message: 'Format de clé invalide. Vérifiez que vous avez copié la clé complète.',
        );
      }

      final serial = CryptoService.extractSerial(key);
      final hashedSerial = CryptoService.hashSerial(serial);

      final existingKey = await getKeyBySerial(hashedSerial);
      if (existingKey != null && existingKey['status'] == 'revoked') {
        return ActivationResult(
          success: false,
          message: 'Cette clé a été révoquée et ne peut plus être utilisée.',
        );
      }

      if (existingKey != null) {
        final existingDevice = existingKey['device_id'] as String?;
        if (existingDevice != null && existingDevice != deviceId) {
          return ActivationResult(
            success: false,
            message: 'Cette clé est déjà utilisée sur un autre appareil.',
          );
        }

        if (existingDevice == deviceId) {
          return ActivationResult(
            success: true,
            message: 'Activation réussie !',
            alreadyActivated: true,
          );
        }
      }

      if (existingKey == null) {
        await createKey(key, hashedSerial, deviceId);
      } else {
        await activateKey(hashedSerial, deviceId);
      }

      return ActivationResult(
        success: true,
        message: 'Activation réussie !',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification: $e');
      }
      return ActivationResult(
        success: false,
        message: 'Erreur lors de la vérification. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>?> createKey(String keyFull, String serialHash, [String? deviceId]) async {
    try {
      final keyData = {
        'serial_hash': serialHash,
        'key_full': keyFull,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'activated_at': DateTime.now().toIso8601String(),
        if (deviceId != null) 'device_id': deviceId,
      };

      final id = await _databaseService.insertActivationKey(keyData);

      if (id > 0) {
        return {
          ...keyData,
          'id': id,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création de la clé: $e');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listActivatedKeys() async {
    try {
      return await _databaseService.getActivationKeysByStatus('active');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des clés actives: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listRevokedKeys() async {
    try {
      return await _databaseService.getActivationKeysByStatus('revoked');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des clés révoquées: $e');
      }
      return [];
    }
  }

  Future<bool> revokeKey(String serialHash, String? reason) async {
    try {
      final result = await _databaseService.updateActivationKeyStatus(
        serialHash: serialHash,
        status: 'revoked',
        revokeReason: reason,
      );
      return result > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la révocation de la clé: $e');
      }
      return false;
    }
  }

  Future<bool> deleteActivatedKey(String serialHash) async {
    try {
      final result = await _databaseService.deleteActivationKey(serialHash);
      return result > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de la clé: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> getKeyBySerial(String serialHash) async {
    try {
      return await _databaseService.getActivationKeyBySerial(serialHash);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la recherche de la clé: $e');
      }
      return null;
    }
  }

  Future<bool> activateKey(String serialHash, String deviceId) async {
    try {
      final result = await _databaseService.updateActivationKeyStatus(
        serialHash: serialHash,
        status: 'active',
        deviceId: deviceId,
      );
      return result > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'activation de la clé: $e');
      }
      return false;
    }
  }

  Future<bool> isDeviceActivated(String deviceId) async {
    try {
      final keys = await listActivatedKeys();
      return keys.any((key) => key['device_id'] == deviceId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de l\'appareil: $e');
      }
      return false;
    }
  }
}

class ActivationResult {
  final bool success;
  final String message;
  final bool alreadyActivated;

  ActivationResult({
    required this.success,
    required this.message,
    this.alreadyActivated = false,
  });
}