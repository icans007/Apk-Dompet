import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';

/// Service autentikasi menggunakan Hive (penyimpanan lokal)
class AuthService extends ChangeNotifier {
  // Box Hive untuk data pengguna
  late Box<UserModel> _userBox;
  // Box untuk pengaturan/preferensi

  UserModel? _currentUser;
  bool _isLoading = true; // Set default true saat inisialisasi
  String? _errorMessage;

  // Getter
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _init();
  }

  /// Inisialisasi service dan cek sesi login
  Future<void> _init() async {
    try {
      // PERBAIKAN: Pastikan Box sudah dibuka.
      // Jika di main.dart belum dibuka, gunakan Hive.openBox
      _userBox = await Hive.openBox<UserModel>('users');

      await _checkLoginSession();
    } catch (e) {
      _setError('Gagal memuat data aplikasi.');
    } finally {
      _setLoading(false);
    }
  }

  /// Cek apakah ada sesi login yang tersimpan (auto-login)
  Future<void> _checkLoginSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('logged_in_user_id');

      if (savedUserId != null) {
        // PERBAIKAN: Mengambil data langsung berdasarkan Key (id) lebih efisien daripada where()
        final user = _userBox.get(savedUserId);
        if (user != null) {
          _currentUser = user;
        } else {
          // Jika ID ada di prefs tapi tidak ada di Hive, hapus session-nya
          await prefs.remove('logged_in_user_id');
        }
      }
    } catch (e) {
      debugPrint('Error checking login session: $e');
    }
  }

  /// Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Daftar pengguna baru
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Cek apakah email sudah terdaftar
      final isEmailTaken = _userBox.values.any(
        (u) => u.email.toLowerCase() == normalizedEmail,
      );

      if (isEmailTaken) {
        _setError('Email sudah terdaftar. Gunakan email lain.');
        return false;
      }

      final newUser = UserModel(
        id: const Uuid().v4(),
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
      );

      // Simpan ke Hive menggunakan ID sebagai Key
      await _userBox.put(newUser.id, newUser);

      _currentUser = newUser;
      await _saveLoginSession(newUser.id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Terjadi kesalahan saat mendaftar.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login dengan email dan password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Cari pengguna berdasarkan email
      // Iterable.cast digunakan untuk keamanan tipe data
      final matchingUsers = _userBox.values.where(
        (u) => u.email.toLowerCase() == normalizedEmail,
      );

      if (matchingUsers.isEmpty) {
        _setError('Email tidak terdaftar.');
        return false;
      }

      final user = matchingUsers.first;
      final hashedPassword = _hashPassword(password);

      if (user.passwordHash != hashedPassword) {
        _setError('Password salah. Coba lagi.');
        return false;
      }

      _currentUser = user;
      await _saveLoginSession(user.id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal login. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout pengguna
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_user_id');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Perbarui profil pengguna
  Future<bool> updateProfile({required String name}) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(name: name.trim());
      await _userBox.put(updatedUser.id, updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal memperbarui profil.');
      return false;
    }
  }

  /// Simpan sesi
  Future<void> _saveLoginSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_user_id', userId);
  }

  // Helper methods
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Jangan notifyListeners di sini agar tidak terjadi redudansi saat dipanggil di awal fungsi
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
