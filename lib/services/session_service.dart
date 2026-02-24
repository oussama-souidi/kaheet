import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../utils/constants.dart';

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

  /// Submit answer to a question
  Future<void> submitAnswer({
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
}
