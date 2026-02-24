/// App constants
class AppConstants {
  // Validation patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static const String passwordMinLength =
      'Password must be at least 8 characters';
  static const int passwordMinCharacters = 8;

  // Route names
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeRoleSelection = '/role-selection';
  static const String routeProfessorDashboard = '/professor-dashboard';
  static const String routeStudentDashboard = '/student-dashboard';
  static const String routeCreateQuiz = '/create-quiz';
  static const String routeQuizList = '/quiz-list';
  static const String routeHostSession = '/host-session';
  static const String routeJoinSession = '/join-session';
  static const String routeQuizTaking = '/quiz-taking';
  static const String routeLeaderboard = '/leaderboard';
  static const String routeQuizHistory = '/quiz-history';
  static const String routeAnalytics = '/analytics';

  // User roles
  static const String roleProfessor = 'professor';
  static const String roleStudent = 'student';

  // Question types
  static const String questionTypeMultipleChoice = 'multiple_choice';
  static const String questionTypeTrueFalse = 'true_false';
  static const String questionTypeShortAnswer = 'short_answer';

  // Session status
  static const String sessionStatusActive = 'active';
  static const String sessionStatusCompleted = 'completed';
  static const String sessionStatusCancelled = 'cancelled';

  // Firestore collections
  static const String collectionUsers = 'users';
  static const String collectionQuizzes = 'quizzes';
  static const String collectionSessions = 'sessions';
  static const String collectionSessionParticipants = 'sessionParticipants';
  static const String collectionQuestionResponses = 'questionResponses';

  // Timing
  static const Duration sessionLoadTimeout = Duration(seconds: 10);
  static const int defaultQuestionTime = 30; // seconds

  // UI Sizing
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 48.0;
}

/// Validators for form inputs
class Validators {
  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.passwordMinCharacters) {
      return 'Password must be at least ${AppConstants.passwordMinCharacters} characters';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate quiz title
  static String? validateQuizTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quiz title is required';
    }
    if (value.length < 3) {
      return 'Quiz title must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Quiz title must not exceed 100 characters';
    }
    return null;
  }

  /// Validate question text
  static String? validateQuestion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Question is required';
    }
    if (value.length < 5) {
      return 'Question must be at least 5 characters';
    }
    return null;
  }

  /// Validate session code
  static String? validateSessionCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Session code is required';
    }
    if (value.length < 4) {
      return 'Session code must be at least 4 characters';
    }
    return null;
  }
}
