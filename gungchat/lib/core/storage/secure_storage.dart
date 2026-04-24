import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  AppSecureStorage({FlutterSecureStorage? client})
      : _client = client ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _client;

  Future<String?> read(String key) => _client.read(key: key);

  Future<void> write(String key, String value) {
    return _client.write(key: key, value: value);
  }

  Future<void> delete(String key) => _client.delete(key: key);

  Future<void> deleteAll() => _client.deleteAll();

  Future<Map<String, String>> readAll() => _client.readAll();
}
