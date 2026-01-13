import '../database/database_helper.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';

class StorageService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();

  // ========== MANAJEMEN USER ==========
  Future<User?> registerUser(User user) async {
    try {
      final id = await _dbHelper.insertUser(user);
      return User.fromMap({
        'id': id.toString(),
        'name': user.name,
        'username': user.username,
        'password': user.password,
      });
    } catch (e) {
      debugPrint('Error register user: $e');
      return null;
    }
  }

  Future<User?> loginUser(String username, String password) async {
    try {
      final user = await _dbHelper.getUserByUsername(username);
      
      // Cek username dan password
      if (user != null && user.password == password) {
        await _authService.setLoggedIn(true, int.parse(user.id));
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error login: $e');
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        return await _dbHelper.getUserById(userId);
      }
      return null;
    } catch (e) {
      debugPrint('Error mengambil user saat ini: $e');
      return null;
    }
  }

  Future<bool> updateUserPassword(String newPassword) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        final updated = await _dbHelper.updateUserPassword(
          int.parse(user.id),
          newPassword,
        );
        return updated > 0; // Berhasil jika ada baris yang terupdate
      }
      return false;
    } catch (e) {
      debugPrint('Error update password: $e');
      return false;
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        // Cek apakah username sudah digunakan oleh user lain
        final existingUser = await _dbHelper.getUserByUsername(newUsername);
        if (existingUser != null && existingUser.id != user.id) {
          return false; // Username sudah digunakan
        }

        final updatedUser = user.copyWith(
          name: newUsername,
          username: newUsername,
        );
        
        final updated = await _dbHelper.updateUser(updatedUser);
        return updated > 0;
      }
      return false;
    } catch (e) {
      debugPrint('Error update username: $e');
      return false;
    }
  }

  // ========== MANAJEMEN TRANSACTION ==========
  Future<List<Transaction>> getTransactions({String? type}) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        return await _dbHelper.getTransactionsByUserId(
          int.parse(user.id),
          type: type,
        );
      }
      return [];
    } catch (e) {
      debugPrint('Error mengambil transaksi: $e');
      return [];
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        await _dbHelper.insertTransaction(
          transaction,
          int.parse(user.id),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error menambah transaksi: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      final updated = await _dbHelper.updateTransaction(transaction);
      return updated > 0;
    } catch (e) {
      debugPrint('Error update transaksi: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      final deleted = await _dbHelper.deleteTransaction(id);
      return deleted > 0;
    } catch (e) {
      debugPrint('Error hapus transaksi: $e');
      return false;
    }
  }

  // ========== ANALYTICS & STATISTIK ==========
  Future<Map<String, double>> getTotals() async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        final income = await _dbHelper.getTotalByType(
          int.parse(user.id),
          'income',
        );
        final expense = await _dbHelper.getTotalByType(
          int.parse(user.id),
          'expense',
        );
        return {'income': income, 'expense': expense};
      }
      return {'income': 0.0, 'expense': 0.0};
    } catch (e) {
      debugPrint('Error mengambil total: $e');
      return {'income': 0.0, 'expense': 0.0};
    }
  }

  Future<Map<String, double>> getCategoryTotals(String type) async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        return await _dbHelper.getCategoryTotals(
          int.parse(user.id),
          type,
        );
      }
      return {};
    } catch (e) {
      debugPrint('Error mengambil total kategori: $e');
      return {};
    }
  }

  // ========== MANAJEMEN SESSION ==========
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  // ========== UTILITAS ==========
  Future<void> close() async {
    await _dbHelper.close();
  }
}