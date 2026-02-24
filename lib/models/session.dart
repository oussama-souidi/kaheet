import 'package:equatable/equatable.dart';

/// Represents a live quiz session
class Session extends Equatable {
  final String id;
  final String quizId;
  final String professorId;
  final DateTime startTime;
  final DateTime? endTime;
  final int currentQuestionIndex;
  final String status; // active, completed, cancelled
  final List<String> participantIds; // List of student IDs
  final int totalParticipants;

  const Session({
    required this.id,
    required this.quizId,
    required this.professorId,
    required this.startTime,
    this.endTime,
    required this.currentQuestionIndex,
    required this.status,
    required this.participantIds,
    required this.totalParticipants,
  });

  Session copyWith({
    String? id,
    String? quizId,
    String? professorId,
    DateTime? startTime,
    DateTime? endTime,
    int? currentQuestionIndex,
    String? status,
    List<String>? participantIds,
    int? totalParticipants,
  }) {
    return Session(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      professorId: professorId ?? this.professorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      totalParticipants: totalParticipants ?? this.totalParticipants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'professorId': professorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'status': status,
      'participantIds': participantIds,
      'totalParticipants': totalParticipants,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      professorId: json['professorId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      status: json['status'] as String,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      totalParticipants: json['totalParticipants'] as int? ?? 0,
    );
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  @override
  List<Object?> get props => [
    id,
    quizId,
    professorId,
    startTime,
    endTime,
    currentQuestionIndex,
    status,
    participantIds,
    totalParticipants,
  ];
}

/// Represents a student's participation in a session
class SessionParticipant extends Equatable {
  final String userId;
  final String sessionId;
  final DateTime joinedAt;
  final int currentScore;
  final List<String> answers; // Answers to each question
  final bool isActive;
  final int correctAnswers;

  const SessionParticipant({
    required this.userId,
    required this.sessionId,
    required this.joinedAt,
    required this.currentScore,
    required this.answers,
    required this.isActive,
    required this.correctAnswers,
  });

  SessionParticipant copyWith({
    String? userId,
    String? sessionId,
    DateTime? joinedAt,
    int? currentScore,
    List<String>? answers,
    bool? isActive,
    int? correctAnswers,
  }) {
    return SessionParticipant(
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      joinedAt: joinedAt ?? this.joinedAt,
      currentScore: currentScore ?? this.currentScore,
      answers: answers ?? this.answers,
      isActive: isActive ?? this.isActive,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'joinedAt': joinedAt.toIso8601String(),
      'currentScore': currentScore,
      'answers': answers,
      'isActive': isActive,
      'correctAnswers': correctAnswers,
    };
  }

  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    return SessionParticipant(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      currentScore: json['currentScore'] as int? ?? 0,
      answers: List<String>.from(json['answers'] as List? ?? []),
      isActive: json['isActive'] as bool? ?? true,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    sessionId,
    joinedAt,
    currentScore,
    answers,
    isActive,
    correctAnswers,
  ];
}

/// Represents a student's response to a question
class QuestionResponse extends Equatable {
  final String sessionId;
  final String questionId;
  final String userId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime; // in milliseconds
  final DateTime timestamp;

  const QuestionResponse({
    required this.sessionId,
    required this.questionId,
    required this.userId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTime,
    required this.timestamp,
  });

  QuestionResponse copyWith({
    String? sessionId,
    String? questionId,
    String? userId,
    String? selectedAnswer,
    bool? isCorrect,
    int? responseTime,
    DateTime? timestamp,
  }) {
    return QuestionResponse(
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      responseTime: responseTime ?? this.responseTime,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'questionId': questionId,
      'userId': userId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'responseTime': responseTime,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      sessionId: json['sessionId'] as String,
      questionId: json['questionId'] as String,
      userId: json['userId'] as String,
      selectedAnswer: json['selectedAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      responseTime: json['responseTime'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    questionId,
    userId,
    selectedAnswer,
    isCorrect,
    responseTime,
    timestamp,
  ];
}
