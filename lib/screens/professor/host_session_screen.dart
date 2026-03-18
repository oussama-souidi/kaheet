import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/services/quiz_service.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_application_1/widgets/leaderboard_widget.dart';

/// Host Session Screen — Kahoot-style lobby + live question presenter
class HostSessionScreen extends StatefulWidget {
  const HostSessionScreen({super.key});

  @override
  State<HostSessionScreen> createState() => _HostSessionScreenState();
}

class _HostSessionScreenState extends State<HostSessionScreen> {
  late Future<List<Quiz>> _quizzesFuture;

  // Phase 1: quiz selection
  Quiz? _selectedQuiz;
  bool _isCreatingSession = false;

  // Phase 2: lobby (waiting for students)
  Session? _lobbySession;

  // Phase 3: active quiz
  Session? _activeSession;
  int _currentQuestionIndex = 0;
  bool _isStartingQuiz = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    final professorId = context.read<AuthProvider>().currentUser?.id ?? '';
    _quizzesFuture = QuizService().getQuizzesByProfessor(professorId);
  }

  // ── Phase transitions ────────────────────────────────────────────────────

  /// Create session in `waiting` state then go to lobby.
  Future<void> _createSession() async {
    if (_selectedQuiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a quiz first')),
      );
      return;
    }
    setState(() => _isCreatingSession = true);
    try {
      final professorId = context.read<AuthProvider>().currentUser?.id ?? '';
      final session = await SessionService().createSession(
        quizId: _selectedQuiz!.id,
        professorId: professorId,
      );
      // Session stays in 'waiting' — students can now join the lobby
      setState(() => _lobbySession = session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isCreatingSession = false);
    }
  }

  /// Lobby → first question active (teacher presses "Start Quiz")
  Future<void> _startQuiz() async {
    final session = _lobbySession;
    if (session == null) return;
    setState(() => _isStartingQuiz = true);
    try {
      await SessionService().startSession(session.id);
      setState(() {
        _activeSession = session;
        _lobbySession = null;
        _currentQuestionIndex = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isStartingQuiz = false);
    }
  }

  Future<void> _cancelLobby() async {
    final session = _lobbySession;
    if (session == null) return;
    try {
      await SessionService().cancelSession(session.id);
      setState(() {
        _lobbySession = null;
        _selectedQuiz = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _endSession() async {
    if (_activeSession == null) return;
    try {
      await SessionService().endSession(_activeSession!.id);
      setState(() {
        _activeSession = null;
        _selectedQuiz = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _nextQuestion() async {
    final quiz = _selectedQuiz;
    final session = _activeSession;
    if (quiz == null || session == null) return;
    if (_currentQuestionIndex < quiz.questions.length - 1) {
      final newIndex = _currentQuestionIndex + 1;
      setState(() => _currentQuestionIndex = newIndex);
      await SessionService().startQuestion(session.id, newIndex);
    }
  }

  Future<void> _previousQuestion() async {
    final session = _activeSession;
    if (_currentQuestionIndex > 0 && session != null) {
      final newIndex = _currentQuestionIndex - 1;
      setState(() => _currentQuestionIndex = newIndex);
      await SessionService().startQuestion(session.id, newIndex);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_activeSession != null && _selectedQuiz != null) {
      return _buildActiveSession();
    }
    if (_lobbySession != null && _selectedQuiz != null) {
      return _buildLobby();
    }
    return _buildSelectQuiz();
  }

  // ── Phase 1: Select Quiz ─────────────────────────────────────────────────

  Widget _buildSelectQuiz() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host a Session'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.surfaceLight,
      body: FutureBuilder<List<Quiz>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a quiz first to start hosting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Select a quiz to host',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final isSelected = _selectedQuiz?.id == quiz.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedQuiz = quiz),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFFE0D0FF),
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '📋',
                                  style: TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${quiz.questions.length} questions • ${quiz.totalPoints} pts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedQuiz != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingSession ? null : _createSession,
                      icon: const Icon(Icons.people_alt, color: Colors.white),
                      label: _isCreatingSession
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Lobby',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.answerGreen,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Phase 2: Lobby ───────────────────────────────────────────────────────

  Widget _buildLobby() {
    final session = _lobbySession!;
    final quiz = _selectedQuiz!;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.accentColor,
        automaticallyImplyLeading: false,
        title: StreamBuilder<Session?>(
          stream: SessionService().getSessionStream(session.id),
          builder: (context, snap) {
            final liveSession = snap.data ?? session;
            return Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${liveSession.totalParticipants} player${liveSession.totalParticipants == 1 ? '' : 's'} joined',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  session.pin,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // PIN display card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Game PIN:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.pin,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share this PIN with students',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Participants list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Students in lobby',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<SessionParticipant>>(
                      stream: SessionService().getParticipantsStream(
                        session.id,
                      ),
                      builder: (context, snap) {
                        final participants = snap.data ?? [];
                        if (participants.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '⏳',
                                      style: TextStyle(fontSize: 36),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Waiting for students to join...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        const avatarColors = [
                          AppTheme.answerRed,
                          AppTheme.answerBlue,
                          AppTheme.answerYellow,
                          AppTheme.answerGreen,
                          AppTheme.hotPink,
                        ];

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.0,
                              ),
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final p = participants[index];
                            final color =
                                avatarColors[index % avatarColors.length];
                            return Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.displayName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      p.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isStartingQuiz ? null : _startQuiz,
                    icon: const Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    label: _isStartingQuiz
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Start Quiz!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.answerGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _cancelLobby,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Cancel Session'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 3: Active session ──────────────────────────────────────────────

  Widget _buildActiveSession() {
    final quiz = _selectedQuiz!;
    final session = _activeSession!;
    final currentQuestion = quiz.questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == quiz.questions.length - 1;

    const colors = [
      AppTheme.answerRed,
      AppTheme.answerBlue,
      AppTheme.answerYellow,
      AppTheme.answerGreen,
    ];
    const symbols = ['▲', '◆', '●', '■'];

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.accentColor,
        automaticallyImplyLeading: false,
        title: StreamBuilder<Session?>(
          stream: SessionService().getSessionStream(session.id),
          builder: (context, snap) {
            final liveSession = snap.data ?? session;
            return Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${liveSession.totalParticipants} player${liveSession.totalParticipants == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  session.pin,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Question progress bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / quiz.questions.length,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.hotPink),
            minHeight: 6,
          ),
          // Question card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Q counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} / ${quiz.questions.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.hotPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentQuestion.points} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Question text card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      currentQuestion.questionText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Answer tiles
                  if (currentQuestion.type == 'multiple_choice')
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: currentQuestion.options
                          .asMap()
                          .entries
                          .map(
                            (e) => _answerTile(
                              e.value,
                              colors[e.key % 4],
                              symbols[e.key % 4],
                              highlight:
                                  e.value == currentQuestion.correctAnswer,
                            ),
                          )
                          .toList(),
                    ),
                  if (currentQuestion.type == 'true_false')
                    Row(
                      children: [
                        Expanded(
                          child: _answerTile(
                            'True',
                            AppTheme.answerGreen,
                            '✔',
                            highlight: currentQuestion.correctAnswer == 'True',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _answerTile(
                            'False',
                            AppTheme.answerRed,
                            '✖',
                            highlight: currentQuestion.correctAnswer == 'False',
                          ),
                        ),
                      ],
                    ),
                  if (currentQuestion.type == 'short_answer')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.edit_note,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '📝 Short Answer Question',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expected answer: ${currentQuestion.correctAnswer}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Students type their answer — you grade it after.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  LeaderboardWidget(sessionId: session.id),
                ],
              ),
            ),
          ),
          // Navigation
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousQuestion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: const Text('◀ Prev'),
                        ),
                      ),
                    if (_currentQuestionIndex > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isLast ? _endSession : _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLast
                              ? AppTheme.answerRed
                              : AppTheme.hotPink,
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(
                          isLast ? '🏁 End Quiz' : 'Next Question ▶',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _endSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.answerRed,
                      ),
                      child: const Text(
                        'End Session Early',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerTile(
    String text,
    Color color,
    String symbol, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? color : color.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: highlight ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (highlight) const Icon(Icons.check, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
