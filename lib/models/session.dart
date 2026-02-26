import 'package:equatable/equatable.dart';

/// Represents a live quiz session with full state machine support
class Session extends Equatable {
  final String id;
  final String quizId;
  final String professorId;
  final DateTime startTime;
  final DateTime? endTime;
  final int currentQuestionIndex;
  final String status;
  final List<String> participantIds;
  final int totalParticipants;
  final String pin;
  final DateTime? questionStartedAt; // set when teacher starts each question

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
    this.pin = '',
    this.questionStartedAt,
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
    String? pin,
    DateTime? questionStartedAt,
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
      pin: pin ?? this.pin,
      questionStartedAt: questionStartedAt ?? this.questionStartedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'quizId': quizId,
    'professorId': professorId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'currentQuestionIndex': currentQuestionIndex,
    'status': status,
    'participantIds': participantIds,
    'totalParticipants': totalParticipants,
    'pin': pin,
    'questionStartedAt': questionStartedAt?.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
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
    pin: json['pin'] as String? ?? '',
    questionStartedAt: json['questionStartedAt'] != null
        ? DateTime.parse(json['questionStartedAt'] as String)
        : null,
  );

  bool get isWaiting => status == 'waiting';
  bool get isQuestionActive => status == 'question_active';
  bool get isQuestionEnded => status == 'question_ended';
  bool get isCompleted => status == 'completed';

  /// Compute remaining seconds for this question from the server timestamp.
  /// Returns null if question not yet started.
  int? remainingSeconds(int timeLimitSeconds) {
    if (questionStartedAt == null) return timeLimitSeconds;
    final elapsed = DateTime.now().difference(questionStartedAt!).inSeconds;
    final remaining = timeLimitSeconds - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

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
    pin,
    questionStartedAt,
  ];
}

/// Represents a student's participation in a session
class SessionParticipant extends Equatable {
  final String userId;
  final String sessionId;
  final String displayName;
  final DateTime joinedAt;
  final int currentScore;
  final List<String> answers;
  final bool isActive;
  final int correctAnswers;

  const SessionParticipant({
    required this.userId,
    required this.sessionId,
    required this.displayName,
    required this.joinedAt,
    required this.currentScore,
    required this.answers,
    required this.isActive,
    required this.correctAnswers,
  });

  SessionParticipant copyWith({
    String? userId,
    String? sessionId,
    String? displayName,
    DateTime? joinedAt,
    int? currentScore,
    List<String>? answers,
    bool? isActive,
    int? correctAnswers,
  }) {
    return SessionParticipant(
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt ?? this.joinedAt,
      currentScore: currentScore ?? this.currentScore,
      answers: answers ?? this.answers,
      isActive: isActive ?? this.isActive,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sessionId': sessionId,
    'displayName': displayName,
    'joinedAt': joinedAt.toIso8601String(),
    'currentScore': currentScore,
    'answers': answers,
    'isActive': isActive,
    'correctAnswers': correctAnswers,
  };

  factory SessionParticipant.fromJson(Map<String, dynamic> json) =>
      SessionParticipant(
        userId: json['userId'] as String,
        sessionId: json['sessionId'] as String,
        displayName: json['displayName'] as String? ?? 'Student',
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        currentScore: json['currentScore'] as int? ?? 0,
        answers: List<String>.from(json['answers'] as List? ?? []),
        isActive: json['isActive'] as bool? ?? true,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    userId,
    sessionId,
    displayName,
    joinedAt,
    currentScore,
    answers,
    isActive,
    correctAnswers,
  ];
}

/// Represents a student's response to a single question
class QuestionResponse extends Equatable {
  final String sessionId;
  final String questionId;
  final String userId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime;
  final DateTime timestamp;
  final bool? manuallyGraded; // for short answer
  final bool? teacherMarkedCorrect; // for short answer

  const QuestionResponse({
    required this.sessionId,
    required this.questionId,
    required this.userId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.responseTime,
    required this.timestamp,
    this.manuallyGraded,
    this.teacherMarkedCorrect,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'questionId': questionId,
    'userId': userId,
    'selectedAnswer': selectedAnswer,
    'isCorrect': isCorrect,
    'responseTime': responseTime,
    'timestamp': timestamp.toIso8601String(),
    'manuallyGraded': manuallyGraded,
    'teacherMarkedCorrect': teacherMarkedCorrect,
  };

  factory QuestionResponse.fromJson(Map<String, dynamic> json) =>
      QuestionResponse(
        sessionId: json['sessionId'] as String,
        questionId: json['questionId'] as String,
        userId: json['userId'] as String,
        selectedAnswer: json['selectedAnswer'] as String,
        isCorrect: json['isCorrect'] as bool,
        responseTime: json['responseTime'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        manuallyGraded: json['manuallyGraded'] as bool?,
        teacherMarkedCorrect: json['teacherMarkedCorrect'] as bool?,
      );

  @override
  List<Object?> get props => [
    sessionId,
    questionId,
    userId,
    selectedAnswer,
    isCorrect,
    responseTime,
    timestamp,
    manuallyGraded,
    teacherMarkedCorrect,
  ];
}
