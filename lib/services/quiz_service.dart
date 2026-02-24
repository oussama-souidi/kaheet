import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz.dart';
import '../utils/constants.dart';

/// Firebase service for managing quizzes
class QuizService {
  static final QuizService _instance = QuizService._internal();

  late final FirebaseFirestore _firestore;

  factory QuizService() {
    return _instance;
  }

  QuizService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Create a new quiz
  Future<Quiz> createQuiz({
    required String title,
    required String description,
    required String professorId,
    required List<Question> questions,
    String? thumbnailUrl,
  }) async {
    try {
      final quizId = const Uuid().v4();
      final totalPoints = questions.fold(0, (sum, q) => sum + q.points);

      final quiz = Quiz(
        id: quizId,
        title: title,
        description: description,
        professorId: professorId,
        questions: questions,
        createdAt: DateTime.now(),
        isPublished: false,
        thumbnailUrl: thumbnailUrl,
        totalPoints: totalPoints,
      );

      await _firestore
          .collection(AppConstants.collectionQuizzes)
          .doc(quizId)
          .set(quiz.toJson());

      return quiz;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific quiz
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionQuizzes)
          .doc(quizId)
          .get();

      if (doc.exists) {
        return Quiz.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all quizzes by professor
  Future<List<Quiz>> getQuizzesByProfessor(String professorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionQuizzes)
          .where('professorId', isEqualTo: professorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Quiz.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of quizzes by professor (real-time updates)
  Stream<List<Quiz>> getQuizzesByProfessorStream(String professorId) {
    return _firestore
        .collection(AppConstants.collectionQuizzes)
        .where('professorId', isEqualTo: professorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Quiz.fromJson(doc.data())).toList();
        });
  }

  /// Update quiz
  Future<void> updateQuiz(Quiz quiz) async {
    try {
      await _firestore
          .collection(AppConstants.collectionQuizzes)
          .doc(quiz.id)
          .update({
            'title': quiz.title,
            'description': quiz.description,
            'questions': quiz.questions.map((q) => q.toJson()).toList(),
            'isPublished': quiz.isPublished,
            'thumbnailUrl': quiz.thumbnailUrl,
            'totalPoints': quiz.totalPoints,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Publish quiz
  Future<void> publishQuiz(String quizId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionQuizzes)
          .doc(quizId)
          .update({
            'isPublished': true,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionQuizzes)
          .doc(quizId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Add question to quiz
  Future<void> addQuestion(String quizId, Question question) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz != null) {
        final updatedQuestions = [...quiz.questions, question];
        final newTotalPoints = updatedQuestions.fold(
          0,
          (sum, q) => sum + q.points,
        );

        await _firestore
            .collection(AppConstants.collectionQuizzes)
            .doc(quizId)
            .update({
              'questions': updatedQuestions.map((q) => q.toJson()).toList(),
              'totalPoints': newTotalPoints,
              'updatedAt': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update question in quiz
  Future<void> updateQuestion(String quizId, Question question) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz != null) {
        final updatedQuestions = quiz.questions.map((q) {
          return q.id == question.id ? question : q;
        }).toList();

        final newTotalPoints = updatedQuestions.fold(
          0,
          (sum, q) => sum + q.points,
        );

        await _firestore
            .collection(AppConstants.collectionQuizzes)
            .doc(quizId)
            .update({
              'questions': updatedQuestions.map((q) => q.toJson()).toList(),
              'totalPoints': newTotalPoints,
              'updatedAt': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete question from quiz
  Future<void> deleteQuestion(String quizId, String questionId) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz != null) {
        final updatedQuestions = quiz.questions
            .where((q) => q.id != questionId)
            .toList();

        final newTotalPoints = updatedQuestions.fold(
          0,
          (sum, q) => sum + q.points,
        );

        await _firestore
            .collection(AppConstants.collectionQuizzes)
            .doc(quizId)
            .update({
              'questions': updatedQuestions.map((q) => q.toJson()).toList(),
              'totalPoints': newTotalPoints,
              'updatedAt': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Search quizzes by title
  Future<List<Quiz>> searchQuizzes(String query) async {
    try {
      // Firestore doesn't support full-text search, so we filter in memory
      final allQuizzes = await _firestore
          .collection(AppConstants.collectionQuizzes)
          .get()
          .then(
            (snapshot) =>
                snapshot.docs.map((doc) => Quiz.fromJson(doc.data())).toList(),
          );

      return allQuizzes
          .where(
            (quiz) =>
                quiz.title.toLowerCase().contains(query.toLowerCase()) ||
                quiz.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
