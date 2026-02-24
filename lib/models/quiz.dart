import 'package:equatable/equatable.dart';

/// Question model for quiz content
class Question extends Equatable {
  final String id;
  final String questionText;
  final String type; // multiple_choice, true_false, short_answer
  final List<String> options; // For multiple choice questions
  final String correctAnswer;
  final int timeLimit; // in seconds
  final String? explanation;
  final int points; // Points for correct answer

  const Question({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.timeLimit,
    this.explanation,
    required this.points,
  });

  Question copyWith({
    String? id,
    String? questionText,
    String? type,
    List<String>? options,
    String? correctAnswer,
    int? timeLimit,
    String? explanation,
    int? points,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      timeLimit: timeLimit ?? this.timeLimit,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'timeLimit': timeLimit,
      'explanation': explanation,
      'points': points,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      type: json['type'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as String,
      timeLimit: json['timeLimit'] as int,
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 10,
    );
  }

  @override
  List<Object?> get props => [
    id,
    questionText,
    type,
    options,
    correctAnswer,
    timeLimit,
    explanation,
    points,
  ];
}

/// Quiz model
class Quiz extends Equatable {
  final String id;
  final String title;
  final String description;
  final String professorId;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final String? thumbnailUrl;
  final int totalPoints;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.professorId,
    required this.questions,
    required this.createdAt,
    this.updatedAt,
    required this.isPublished,
    this.thumbnailUrl,
    required this.totalPoints,
  });

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? professorId,
    List<Question>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    String? thumbnailUrl,
    int? totalPoints,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      professorId: professorId ?? this.professorId,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'professorId': professorId,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublished': isPublished,
      'thumbnailUrl': thumbnailUrl,
      'totalPoints': totalPoints,
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      professorId: json['professorId'] as String,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isPublished: json['isPublished'] as bool? ?? false,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      totalPoints: json['totalPoints'] as int? ?? 0,
    );
  }

  int get questionCount => questions.length;

  int calculateTotalPoints() {
    return questions.fold(0, (sum, q) => sum + q.points);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    professorId,
    questions,
    createdAt,
    updatedAt,
    isPublished,
    thumbnailUrl,
    totalPoints,
  ];
}
