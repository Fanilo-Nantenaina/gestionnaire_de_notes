import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class CryptoService {
  static String get _secretPhrase {
    final parts = [
      'APP',
      'Flutter',
      'ONG',
      '2025',
    ];

    final dateSalt = DateTime.now().year.toString();

    return '${parts.join('_')}_$dateSalt';
  }

  static String generateKey({int serialLength = 10}) {
    final random = Random.secure();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    String serial = '';
    for (int i = 0; i < serialLength; i++) {
      serial += chars[random.nextInt(chars.length)];
    }

    final signature = _generateSignature(serial);

    return '$serial:$signature';
  }

  static String _generateSignature(String serial) {
    final key = utf8.encode(_secretPhrase);
    final bytes = utf8.encode(serial);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString().substring(0, 16).toUpperCase();
  }

  static bool verifyKey(String key) {
    try {
      if (!key.contains(':')) return false;

      final parts = key.split(':');
      if (parts.length != 2) return false;

      final serial = parts[0];
      final providedSignature = parts[1];

      if (!RegExp(r'^[A-Z0-9_]{1,20}$').hasMatch(serial)) return false;

      final expectedSignature = _generateSignature(serial);

      return _secureCompare(providedSignature, expectedSignature);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de la clé: $e');
      }
      return false;
    }
  }

  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  static String extractSerial(String key) {
    if (!key.contains(':')) return '';
    return key.split(':')[0];
  }

  static String hashSerial(String serial) {
    final bytes = utf8.encode(serial + _secretPhrase);
    return sha256.convert(bytes).toString();
  }

  static Future<String> generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = 'UNKNOWN_DEVICE';
      }

      return hashSerial(deviceId);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la génération de l\'ID appareil: $e');
      }
      return 'ERROR_DEVICE_ID';
    }
  }
}