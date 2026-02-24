import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../utils/constants.dart';

// Model classes
class SessionParticipant extends Equatable {
  final String userId;
  final String sessionId;
  final DateTime joinedAt;
  final int currentScore;
  final List<String> answers;
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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'joinedAt': joinedAt.toString(),
      'currentScore': currentScore,
      'answers': answers,
      'isActive': isActive,
      'correctAnswers': correctAnswers,
    };
  }

  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    return SessionParticipant(
      userId: json['userId'] ?? '',
      sessionId: json['sessionId'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toString()),
      currentScore: json['currentScore'] ?? 0,
      answers: List<String>.from(json['answers'] ?? []),
      isActive: json['isActive'] ?? true,
      correctAnswers: json['correctAnswers'] ?? 0,
    );
  }

  @override
  List<Object> get props => [userId, sessionId, currentScore, correctAnswers];
}

class QuestionResponse extends Equatable {
  final String sessionId;
  final String questionId;
  final String userId;
  final String selectedAnswer;
  final bool isCorrect;
  final int responseTime;
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

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'questionId': questionId,
      'userId': userId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'responseTime': responseTime,
      'timestamp': timestamp.toString(),
    };
  }

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      sessionId: json['sessionId'] ?? '',
      questionId: json['questionId'] ?? '',
      userId: json['userId'] ?? '',
      selectedAnswer: json['selectedAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      responseTime: json['responseTime'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
    );
  }

  @override
  List<Object> get props => [
    sessionId,
    questionId,
    userId,
    selectedAnswer,
    isCorrect,
  ];
}

/// Firebase service for managing quiz sessions
class SessionService {
  static final SessionService _instance = SessionService._internal();

  late final FirebaseFirestore _firestore;

  factory SessionService() {
    return _instance;
  }

  SessionService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Create and host a new session
  Future<Session> createSession({
    required String quizId,
    required String professorId,
  }) async {
    try {
      final sessionId = const Uuid().v4();
      final session = Session(
        id: sessionId,
        quizId: quizId,
        professorId: professorId,
        startTime: DateTime.now(),
        currentQuestionIndex: 0,
        status: AppConstants.sessionStatusActive,
        participantIds: [],
        totalParticipants: 0,
      );

      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .set(session.toJson());

      return session;
    } catch (e) {
      rethrow;
    }
  }

  /// Get session
  Future<Session?> getSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .get();

      if (doc.exists) {
        return Session.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream session data (real-time updates)
  Stream<Session?> getSessionStream(String sessionId) {
    return _firestore
        .collection(AppConstants.collectionSessions)
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return Session.fromJson(snapshot.data()!);
          }
          return null;
        });
  }

  /// Join session as a student
  Future<SessionParticipant> joinSession({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      final participant = SessionParticipant(
        userId: userId,
        sessionId: sessionId,
        joinedAt: DateTime.now(),
        currentScore: 0,
        answers: [],
        isActive: true,
        correctAnswers: 0,
      );

      // Save participant
      await _firestore
          .collection(AppConstants.collectionSessionParticipants)
          .doc(sessionId)
          .collection('participants')
          .doc(userId)
          .set(participant.toJson());

      // Update session participant count
      final updatedParticipantIds = [...session.participantIds, userId];
      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .update({
            'participantIds': updatedParticipantIds,
            'totalParticipants': updatedParticipantIds.length,
          });

      return participant;
    } catch (e) {
      rethrow;
    }
  }

  /// Get participant data
  Future<SessionParticipant?> getParticipant({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionSessionParticipants)
          .doc(sessionId)
          .collection('participants')
          .doc(userId)
          .get();

      if (doc.exists) {
        return SessionParticipant.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream participant data (real-time)
  Stream<SessionParticipant?> getParticipantStream({
    required String sessionId,
    required String userId,
  }) {
    return _firestore
        .collection(AppConstants.collectionSessionParticipants)
        .doc(sessionId)
        .collection('participants')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return SessionParticipant.fromJson(snapshot.data()!);
          }
          return null;
        });
  }

  /// Get all participants in a session
  Future<List<SessionParticipant>> getSessionParticipants(
    String sessionId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionSessionParticipants)
          .doc(sessionId)
          .collection('participants')
          .orderBy('currentScore', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SessionParticipant.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream participants for leaderboard
  Stream<List<SessionParticipant>> getSessionParticipantsStream(
    String sessionId,
  ) {
    return _firestore
        .collection(AppConstants.collectionSessionParticipants)
        .doc(sessionId)
        .collection('participants')
        .orderBy('currentScore', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SessionParticipant.fromJson(doc.data()))
              .toList();
        });
  }

  /// Submit single answer to a question
  Future<void> submitSingleAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String answer,
    required bool isCorrect,
    required int responseTime,
  }) async {
    try {
      final responseId = const Uuid().v4();
      final response = QuestionResponse(
        sessionId: sessionId,
        questionId: questionId,
        userId: userId,
        selectedAnswer: answer,
        isCorrect: isCorrect,
        responseTime: responseTime,
        timestamp: DateTime.now(),
      );

      // Save response
      await _firestore
          .collection(AppConstants.collectionQuestionResponses)
          .doc(responseId)
          .set(response.toJson());

      // Update participant's answer
      final participant = await getParticipant(
        sessionId: sessionId,
        userId: userId,
      );

      if (participant != null) {
        final updatedAnswers = [...participant.answers, answer];
        int updatedScore = participant.currentScore;
        int updatedCorrectAnswers = participant.correctAnswers;

        if (isCorrect) {
          updatedScore += 10; // Default 10 points per correct answer
          updatedCorrectAnswers += 1;
        }

        await _firestore
            .collection(AppConstants.collectionSessionParticipants)
            .doc(sessionId)
            .collection('participants')
            .doc(userId)
            .update({
              'answers': updatedAnswers,
              'currentScore': updatedScore,
              'correctAnswers': updatedCorrectAnswers,
            });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Move to next question
  Future<void> nextQuestion(String sessionId, int nextQuestionIndex) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .update({'currentQuestionIndex': nextQuestionIndex});
    } catch (e) {
      rethrow;
    }
  }

  /// End session
  Future<void> endSession(String sessionId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .update({
            'status': AppConstants.sessionStatusCompleted,
            'endTime': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Get responses for a question
  Future<List<QuestionResponse>> getQuestionResponses({
    required String sessionId,
    required String questionId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionQuestionResponses)
          .where('sessionId', isEqualTo: sessionId)
          .where('questionId', isEqualTo: questionId)
          .get();

      return snapshot.docs
          .map((doc) => QuestionResponse.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get session history by professor
  Future<List<Session>> getProfessorSessionHistory(String professorId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionSessions)
          .where('professorId', isEqualTo: professorId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map((doc) => Session.fromJson(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get active sessions
  Future<List<Session>> getActiveSessions() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionSessions)
          .where('status', isEqualTo: AppConstants.sessionStatusActive)
          .get();

      return snapshot.docs.map((doc) => Session.fromJson(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Submit complete quiz (all answers) - used at the end of quiz
  Future<void> submitAnswer({
    required String sessionId,
    required String studentId,
    required List<String?> answers,
    required int score,
  }) async {
    try {
      // Update participant's final score
      await _firestore
          .collection(AppConstants.collectionSessionParticipants)
          .doc(sessionId)
          .collection('participants')
          .doc(studentId)
          .update({
            'answers': answers,
            'currentScore': score,
            'isActive': false,
          });
    } catch (e) {
      rethrow;
    }
  }
}
