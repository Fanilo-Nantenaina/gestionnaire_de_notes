import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _secureStorage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;

  Future<void> initialize() async {
    try {
      String? keyString = await _secureStorage.read(key: 'encryption_key');
      String? ivString = await _secureStorage.read(key: 'encryption_iv');

      if (keyString == null || ivString == null) {
        final key = encrypt.Key.fromSecureRandom(32);
        final iv = encrypt.IV.fromSecureRandom(16);

        await _secureStorage.write(key: 'encryption_key', value: base64.encode(key.bytes));
        await _secureStorage.write(key: 'encryption_iv', value: base64.encode(iv.bytes));

        _encrypter = encrypt.Encrypter(encrypt.AES(key));
        _iv = iv;
      } else {
        final keyBytes = base64.decode(keyString);
        final ivBytes = base64.decode(ivString);

        final key = encrypt.Key(Uint8List.fromList(keyBytes));
        final iv = encrypt.IV(Uint8List.fromList(ivBytes));

        _encrypter = encrypt.Encrypter(encrypt.AES(key));
        _iv = iv;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation du chiffrement: $e');
      }
      rethrow;
    }
  }

  String encryptText(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Service de chiffrement non initialisé');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chiffrement: $e');
      }
      rethrow;
    }
  }

  String decryptText(String encryptedText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Service de chiffrement non initialisé');
    }

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du déchiffrement: $e');
      }
      rethrow;
    }
  }

  bool isEncrypted(String text) {
    try {
      base64.decode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetKeys() async {
    await _secureStorage.delete(key: 'encryption_key');
    await _secureStorage.delete(key: 'encryption_iv');
    _encrypter = null;
    _iv = null;
    await initialize();
  }

  Future<String?> exportKey() async {
    try {
      final keyString = await _secureStorage.read(key: 'encryption_key');
      final ivString = await _secureStorage.read(key: 'encryption_iv');

      if (keyString == null || ivString == null) return null;

      return '$keyString:$ivString';
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'export de la clé: $e');
      }
      return null;
    }
  }

  Future<bool> importKey(String keyData) async {
    try {
      final parts = keyData.split(':');
      if (parts.length != 2) return false;

      await _secureStorage.write(key: 'encryption_key', value: parts[0]);
      await _secureStorage.write(key: 'encryption_iv', value: parts[1]);

      await initialize();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'import de la clé: $e');
      }
      return false;
    }
  }
}
