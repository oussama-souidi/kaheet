import 'package:equatable/equatable.dart';

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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create user from Firestore JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
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
