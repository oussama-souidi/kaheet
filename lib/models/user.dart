import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a professor or student
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role; // 'professor' or 'student'
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a copy of this user with modified fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert user to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create user from Firestore JSON
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Safely get all fields with type checking
      final id = json['id'];
      final email = json['email'];
      final name = json['name'];
      final role = json['role'];
      final avatarUrl = json['avatarUrl'];
      final createdAtValue = json['createdAt'];
      final updatedAtValue = json['updatedAt'];

      if (id is! String ||
          email is! String ||
          name is! String ||
          role is! String) {
        throw FormatException('Invalid user data types');
      }

      // Handle createdAt
      DateTime parsedCreatedAt;
      if (createdAtValue is Timestamp) {
        parsedCreatedAt = createdAtValue.toDate();
      } else if (createdAtValue is String) {
        parsedCreatedAt = DateTime.parse(createdAtValue);
      } else if (createdAtValue is DateTime) {
        parsedCreatedAt = createdAtValue;
      } else {
        parsedCreatedAt = DateTime.now();
      }

      // Handle updatedAt
      DateTime? parsedUpdatedAt;
      if (updatedAtValue is Timestamp) {
        parsedUpdatedAt = updatedAtValue.toDate();
      } else if (updatedAtValue is String) {
        parsedUpdatedAt = DateTime.parse(updatedAtValue);
      } else if (updatedAtValue is DateTime) {
        parsedUpdatedAt = updatedAtValue;
      }

      return User(
        id: id,
        email: email,
        name: name,
        role: role,
        avatarUrl: avatarUrl is String ? avatarUrl : null,
        createdAt: parsedCreatedAt,
        updatedAt: parsedUpdatedAt,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is a professor
  bool get isProfessor => role == 'professor';

  /// Check if user is a student
  bool get isStudent => role == 'student';

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    avatarUrl,
    createdAt,
    updatedAt,
  ];
}
