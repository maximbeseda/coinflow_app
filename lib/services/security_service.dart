import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart'; // ТЕПЕР БУДЕ ВИКОРИСТАНО

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _pinKey = 'user_secure_pin_hash';
  static const String _biometricsEnabledKey = 'use_biometrics';

  static Future<bool> canUseBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint("Помилка перевірки біометрії: $e");
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      // Використовуємо dynamic, щоб VS Code мовчав,
      // і передаємо ТОЧНО ті параметри, які телефон просить у логах!
      return await (_auth as dynamic).authenticate(
        localizedReason: localizedReason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'security'.tr(),
            cancelButton: 'cancel'.tr(),
          ),
          IOSAuthMessages(cancelButton: 'cancel'.tr()),
        ],
        // Передаємо параметри напряму, як того вимагає скомпільований движок:
        biometricOnly: true,
        persistAcrossBackgrounding: true, // Це старий аналог stickyAuth
      );
    } catch (e) {
      debugPrint("Помилка авторизації: $e");
      return false;
    }
  }

  static Future<void> setBiometricsEnabled(bool isEnabled) async {
    await _secureStorage.write(
      key: _biometricsEnabledKey,
      value: isEnabled.toString(),
    );
  }

  static Future<bool> isBiometricsEnabled() async {
    final value = await _secureStorage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  static Uint8List deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  static Future<void> setPinCode(String pin) async {
    final keyBytes = deriveKey(pin);
    final hashToStore = base64Encode(keyBytes);
    await _secureStorage.write(key: _pinKey, value: hashToStore);
  }

  static Future<bool> verifyPinCode(String enteredPin) async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;
    final enteredKeyBytes = deriveKey(enteredPin);
    final enteredHash = base64Encode(enteredKeyBytes);
    return storedHash == enteredHash;
  }

  static Future<bool> isPinSet() async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    return storedHash != null;
  }

  static Future<void> disableSecurity() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _biometricsEnabledKey);
  }
}
