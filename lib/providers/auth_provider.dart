import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider for managing authentication state using ChangeNotifier
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfessor => _currentUser?.isProfessor ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  AuthProvider() {
    _setupAuthListener();
  }

  /// Listen to Firebase auth state changes
  void _setupAuthListener() {
    _authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final user = await _authService.getUser(uid);
      _currentUser = user;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load user data';
      notifyListeners();
    }
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String name,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        email: email,
        name: name,
        password: password,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in existing user
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out';
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String uid,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      await _authService.updateProfile(
        uid: uid,
        name: name,
        avatarUrl: avatarUrl,
      );
      if (name != null) {
        _currentUser = _currentUser?.copyWith(name: name);
      }
      if (avatarUrl != null) {
        _currentUser = _currentUser?.copyWith(avatarUrl: avatarUrl);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount(String uid) async {
    try {
      await _authService.deleteAccount(uid);
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
