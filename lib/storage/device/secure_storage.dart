import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  String username = "";
  String accessCode = "";
  String refreshToken = "";
  String accessToken = "";
  DateTime dateTokenExpires = DateTime.now();
  bool dataPrivacyCheck = false;

  // Singleton instance
  static final SecureStorage _secureStorage = SecureStorage._internal();
  final storage = const FlutterSecureStorage();

  // Public factory constructor for accessing the singleton instance
  factory SecureStorage() {
    return _secureStorage;
  }

  // Private named constructor
  SecureStorage._internal();

  //class constructor
  Future<void> initialize() async {
    username = await readStorageData("username") ?? "";
    accessCode = await readStorageData("accessCode") ?? "";
    refreshToken = await readStorageData("refreshToken") ?? "";
    accessToken = await readStorageData("accessToken") ?? "";
    String tokenExpiresDate = await readStorageData("dateTokenExpires") ?? "";
    if (tokenExpiresDate.isEmpty) {
      dateTokenExpires = DateTime.now().add(const Duration(seconds: 36000));
      await writeStorageData("dateTokenExpires", dateTokenExpires.toString());
    }
    else {
      dateTokenExpires = DateTime.parse(tokenExpiresDate);
      await writeStorageData("dateTokenExpires", dateTokenExpires.toString());
    }
    dataPrivacyCheck = bool.parse(await readStorageData("dataPrivacyCheck") ?? "false", caseSensitive: false);
  }

  Future<String?> readStorageData(String key) async {
    return await storage.read(key: key);
  }

  Future<void> writeStorageData(String key, var value) async {
    await storage.write(key: key, value: value);
  }

}