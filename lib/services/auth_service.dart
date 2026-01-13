import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Key untuk penyimpanan status login
  static const String _keyIsLoggedIn = 'is_logged_in';
  
  // Key untuk penyimpanan ID user yang sedang login
  static const String _keyCurrentUserId = 'current_user_id';

  // Menyimpan status login dan ID user
  Future<void> setLoggedIn(bool value, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
    
    if (value) {
      await prefs.setInt(_keyCurrentUserId, userId); // Simpan ID user jika login
    } else {
      await prefs.remove(_keyCurrentUserId); // Hapus ID user jika logout
    }
  }

  // Mengecek apakah user sedang login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false; // Default false jika null
  }

  // Mendapatkan ID user yang sedang login
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentUserId); // Return null jika belum login
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false); // Set status login menjadi false
    await prefs.remove(_keyCurrentUserId); // Hapus ID user
  }
}