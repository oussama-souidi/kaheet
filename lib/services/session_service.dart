import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../utils/constants.dart';

/// Firebase service for managing quiz sessions (state-machine based)
class SessionService {
  static final SessionService _instance = SessionService._internal();
  late final FirebaseFirestore _firestore;

  factory SessionService() => _instance;

  SessionService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(AppConstants.collectionSessions);

  CollectionReference<Map<String, dynamic>> _participants(String sessionId) =>
      _firestore
          .collection(AppConstants.collectionSessionParticipants)
          .doc(sessionId)
          .collection('participants');

  // ─── Create / Read ────────────────────────────────────────────────────────

  /// Create a new session in "waiting" (lobby) state
  Future<Session> createSession({
    required String quizId,
    required String professorId,
  }) async {
    final sessionId = const Uuid().v4();
    final pin = sessionId.replaceAll('-', '').substring(0, 6).toUpperCase();

    final session = Session(
      id: sessionId,
      quizId: quizId,
      professorId: professorId,
      startTime: DateTime.now(),
      currentQuestionIndex: 0,
      status: AppConstants.sessionStatusWaiting,
      participantIds: [],
      totalParticipants: 0,
      pin: pin,
    );

    await _sessions.doc(sessionId).set(session.toJson());
    return session;
  }

  Future<Session?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return Session.fromJson(doc.data()!);
  }

  /// Look up an active/waiting session by its short PIN
  Future<Session?> getSessionByPin(String pin) async {
    final snap = await _sessions
        .where('pin', isEqualTo: pin.toUpperCase())
        .where(
          'status',
          whereNotIn: [
            AppConstants.sessionStatusCompleted,
            AppConstants.sessionStatusCancelled,
          ],
        )
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Session.fromJson(snap.docs.first.data());
  }

  Stream<Session?> getSessionStream(String sessionId) => _sessions
      .doc(sessionId)
      .snapshots()
      .map((s) => s.exists ? Session.fromJson(s.data()!) : null);

  // ─── State Machine ────────────────────────────────────────────────────────

  /// Lobby → first question active (teacher presses "Start Quiz")
  Future<void> startSession(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': AppConstants.sessionStatusQuestionActive,
      'currentQuestionIndex': 0,
      'questionStartedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Transition to next question OR stay on same question when teacher
  /// manually starts it (question_ended → question_active)
  Future<void> startQuestion(String sessionId, int questionIndex) async {
    await _sessions.doc(sessionId).update({
      'status': AppConstants.sessionStatusQuestionActive,
      'currentQuestionIndex': questionIndex,
      'questionStartedAt': DateTime.now().toIso8601String(),
    });
  }

  /// End the current question — show results (question_active → question_ended)
  Future<void> endQuestion(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': AppConstants.sessionStatusQuestionEnded,
    });
  }

  /// End the whole session
  Future<void> endSession(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': AppConstants.sessionStatusCompleted,
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  /// Cancel session from lobby
  Future<void> cancelSession(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': AppConstants.sessionStatusCancelled,
    });
  }

  // ─── Participants ─────────────────────────────────────────────────────────

  /// Student joins the session (works even after quiz has started)
  Future<SessionParticipant> joinSession({
    required String sessionId,
    required String userId,
    required String displayName,
  }) async {
    final participant = SessionParticipant(
      userId: userId,
      sessionId: sessionId,
      displayName: displayName,
      joinedAt: DateTime.now(),
      currentScore: 0,
      answers: [],
      isActive: true,
      correctAnswers: 0,
    );

    await _participants(sessionId).doc(userId).set(participant.toJson());

    // Upsert participantIds on the session doc
    await _sessions.doc(sessionId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
      'totalParticipants': FieldValue.increment(1),
    });

    return participant;
  }

  Stream<List<SessionParticipant>> getParticipantsStream(String sessionId) =>
      _participants(sessionId)
          .orderBy('currentScore', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => SessionParticipant.fromJson(d.data()))
                .toList(),
          );

  Future<List<SessionParticipant>> getParticipants(String sessionId) async {
    final snap = await _participants(
      sessionId,
    ).orderBy('currentScore', descending: true).get();
    return snap.docs.map((d) => SessionParticipant.fromJson(d.data())).toList();
  }

  Future<SessionParticipant?> getParticipant({
    required String sessionId,
    required String userId,
  }) async {
    final doc = await _participants(sessionId).doc(userId).get();
    if (!doc.exists) return null;
    return SessionParticipant.fromJson(doc.data()!);
  }

  Stream<SessionParticipant?> getParticipantStream({
    required String sessionId,
    required String userId,
  }) => _participants(sessionId)
      .doc(userId)
      .snapshots()
      .map((s) => s.exists ? SessionParticipant.fromJson(s.data()!) : null);

  // ─── Answers ──────────────────────────────────────────────────────────────

  /// Submit a confirmed answer for a question
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String answer,
    required bool isCorrect,
    required int responseTimeMs,
    required int pointsEarned,
  }) async {
    final responseId = const Uuid().v4();
    final response = QuestionResponse(
      sessionId: sessionId,
      questionId: questionId,
      userId: userId,
      selectedAnswer: answer,
      isCorrect: isCorrect,
      responseTime: responseTimeMs,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.collectionQuestionResponses)
        .doc(responseId)
        .set(response.toJson());

    // Update participant score & answer list
    await _participants(sessionId).doc(userId).update({
      'answers': FieldValue.arrayUnion([answer]),
      'currentScore': FieldValue.increment(pointsEarned),
      if (isCorrect) 'correctAnswers': FieldValue.increment(1),
    });
  }

  /// Get all responses for a given question (teacher leaderboard / grading)
  Future<List<QuestionResponse>> getResponsesForQuestion({
    required String sessionId,
    required String questionId,
  }) async {
    final snap = await _firestore
        .collection(AppConstants.collectionQuestionResponses)
        .where('sessionId', isEqualTo: sessionId)
        .where('questionId', isEqualTo: questionId)
        .get();
    return snap.docs.map((d) => QuestionResponse.fromJson(d.data())).toList();
  }

  /// Get all short-answer responses for manual grading
  Future<List<QuestionResponse>> getShortAnswerResponses({
    required String sessionId,
    required String questionId,
  }) async {
    final snap = await _firestore
        .collection(AppConstants.collectionQuestionResponses)
        .where('sessionId', isEqualTo: sessionId)
        .where('questionId', isEqualTo: questionId)
        .where('manuallyGraded', isNull: true)
        .get();
    return snap.docs.map((d) => QuestionResponse.fromJson(d.data())).toList();
  }

  /// Teacher manually grades a short answer
  Future<void> markShortAnswer({
    required String responseId,
    required String sessionId,
    required String userId,
    required bool isCorrect,
    required int pointsToAward,
  }) async {
    await _firestore
        .collection(AppConstants.collectionQuestionResponses)
        .doc(responseId)
        .update({
          'isCorrect': isCorrect,
          'manuallyGraded': true,
          'teacherMarkedCorrect': isCorrect,
        });

    if (isCorrect) {
      await _participants(sessionId).doc(userId).update({
        'currentScore': FieldValue.increment(pointsToAward),
        'correctAnswers': FieldValue.increment(1),
      });
    }
  }

  // ─── History ──────────────────────────────────────────────────────────────

  Future<List<Session>> getProfessorSessions(String professorId) async {
    final snap = await _sessions
        .where('professorId', isEqualTo: professorId)
        .orderBy('startTime', descending: true)
        .get();
    return snap.docs.map((d) => Session.fromJson(d.data())).toList();
  }
}
