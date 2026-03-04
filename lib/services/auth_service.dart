import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Authentication service using Firebase Auth and Firestore
class AuthService {
  static final AuthService _instance = AuthService._internal();

  late final firebase_auth.FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _firebaseAuth = firebase_auth.FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  /// Get current Firebase user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user as stream
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<User> signUp({
    required String email,
    required String name,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user account');
      }

      // Create user document in Firestore
      final user = User(
        id: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson(), SetOptions(merge: true));

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<User> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Fetch user document from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final data = userDoc.data();
      if (data == null) {
        throw Exception('User data is empty');
      }

      return User.fromJson(data);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get user data from Firestore
  Future<User?> getUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data == null) {
          return null;
        }
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of current user data
  Stream<User?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      try {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            return User.fromJson(data);
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    });
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      // Build the updates map only with non-null values
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
        'name': ?name,
        'avatarUrl': ?avatarUrl,
      };

      await _firestore.collection('users').doc(uid).update(updates);

      // Update display name in Firebase Auth if provided
      if (name != null && _firebaseAuth.currentUser != null) {
        await _firebaseAuth.currentUser!.updateDisplayName(name);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String uid) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete Firebase Auth account
      await _firebaseAuth.currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
