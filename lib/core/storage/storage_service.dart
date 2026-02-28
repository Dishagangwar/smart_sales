import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  static const _selectedRoleKey = 'userRole';
  static const _savedEmailKey = 'savedEmail';
  static const _savedPasswordKey = 'savedPassword';

  // Role ab token ke andar hai, isliye alag se save karne ki zaroorat nahi
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _selectedRoleKey, value: role);
  }

  // --- REMEMBER ME CREDENTIALS ---
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _storage.read(key: _savedEmailKey);
    final password = await _storage.read(key: _savedPasswordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
  }

  // Naya logic: Token decode karke role nikalna
  Future<String?> getRole() async {
  String? token = await getToken();
  if (token != null) {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // 1. JWT se roles nikalo (Jo ki ek List ho sakti hai)
      var roles = decodedToken['roles'];

      // 2. Agar roles ek List hai, toh uska pehla element le lo
      if (roles is List && roles.isNotEmpty) {
        return roles[0].toString(); // e.g., ["ADMIN"] -> "ADMIN"
      } 
      
      // 3. Agar roles pehle se hi String hai
      return roles?.toString();
    } catch (e) {
      print("Decode Error: $e");
      return null;
    }
  }
  return null;
}
  // 4. Clear Storage (Logout ke liye)
  Future<void> clearStorage() async {
    // SECURITY: We only delete session data here so we don't accidentally wipe Remember Me credentials
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _selectedRoleKey);
    print("Session tokens cleared successfully.");
  }
}