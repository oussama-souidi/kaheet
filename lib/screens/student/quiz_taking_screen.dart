import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'dart:math' as math;

/// Live Quiz Taking Screen — Kahoot-style 4-color immersive UI
class QuizTakingScreen extends StatefulWidget {
  final Session session;
  final Quiz quiz;
  final String studentId;

  const QuizTakingScreen({
    required this.session,
    required this.quiz,
    required this.studentId,
    super.key,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen>
    with TickerProviderStateMixin {
  late List<String?> _selectedAnswers;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _answered = false;
  DateTime? _questionStartTime;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _answerRevealController;

  static const _colors = [
    AppTheme.answerRed,
    AppTheme.answerBlue,
    AppTheme.answerYellow,
    AppTheme.answerGreen,
  ];
  static const _symbols = ['▲', '◆', '●', '■'];

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<String?>.filled(widget.quiz.questions.length, null);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _answerRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _answered = false;
    _answerRevealController.reset();
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    _timeRemaining = currentQuestion.timeLimit;
    _questionStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          timer.cancel();
          if (!_answered) {
            // Auto-advance: time ran out, no answer
            _handleTimeOut();
          }
        }
      });
    });
  }

  void _handleTimeOut() {
    setState(() => _answered = true);
    _answerRevealController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _goToNextOrSubmit();
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return; // Already answered
    _timer?.cancel();

    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;

    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
      _answered = true;
    });

    _answerRevealController.forward();

    // Submit single answer to Firestore
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final isCorrect =
        answer.toLowerCase() == currentQuestion.correctAnswer.toLowerCase();
    if (isCorrect) {
      _score += currentQuestion.points;
    }
    SessionService().submitSingleAnswer(
      sessionId: widget.session.id,
      questionId: currentQuestion.id,
      userId: widget.studentId,
      answer: answer,
      isCorrect: isCorrect,
      responseTime: responseTime,
      pointsEarned: isCorrect ? currentQuestion.points : 0,
    );

    // Wait 2s then advance
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _goToNextOrSubmit();
    });
  }

  void _goToNextOrSubmit() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startTimer();
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    try {
      await SessionService().submitAnswer(
        sessionId: widget.session.id,
        studentId: widget.studentId,
        answers: _selectedAnswers,
        score: _score,
      );
      setState(() => _quizCompleted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _answerRevealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) return _buildResults();

    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;
    final timerPercent = _timeRemaining / currentQuestion.timeLimit;
    final timerColor = _timeRemaining <= 5
        ? AppTheme.answerRed
        : _timeRemaining <= 15
        ? AppTheme.answerYellow
        : Colors.white;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_score pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Circular countdown
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(52, 52),
                            painter: _TimerArcPainter(
                              progress: timerPercent,
                              color: timerColor,
                            ),
                          ),
                          Text(
                            '$_timeRemaining',
                            style: TextStyle(
                              color: timerColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Question counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.hotPink,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Question card ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 100),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    currentQuestion.questionText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Answer tiles ──────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildAnswerTiles(currentQuestion),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerTiles(Question question) {
    List<String> options;
    if (question.type == 'multiple_choice') {
      options = question.options;
    } else if (question.type == 'true_false') {
      options = ['True', 'False'];
    } else {
      // Short answer — just show a centered text indicator
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: const Text(
                '📝 Short Answer\nAnswer recorded by your teacher',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final isGrid = options.length == 4;
    if (isGrid) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.zero,
        childAspectRatio: 2.0,
        children: options.asMap().entries.map((entry) {
          return _answerButton(
            question,
            entry.value,
            _colors[entry.key % 4],
            _symbols[entry.key % 4],
          );
        }).toList(),
      );
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _answerButton(
              question,
              entry.value,
              _colors[entry.key % 4],
              _symbols[entry.key % 4],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _answerButton(
    Question question,
    String option,
    Color color,
    String symbol,
  ) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == option;
    final isCorrect =
        option.toLowerCase() == question.correctAnswer.toLowerCase();
    final showReveal = _answered;

    Color tileColor = color;
    if (showReveal) {
      if (isCorrect) {
        tileColor = AppTheme.answerGreen;
      } else if (isSelected && !isCorrect) {
        tileColor = AppTheme.answerRed;
      } else {
        tileColor = color.withValues(alpha: 0.4);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: showReveal && isCorrect
            ? Border.all(color: Colors.white, width: 3)
            : null,
        boxShadow: !_answered
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: _answered ? null : () => _selectAnswer(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      showReveal && isCorrect
                          ? '✔'
                          : (showReveal && isSelected && !isCorrect)
                          ? '✖'
                          : symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final totalPoints = widget.quiz.totalPoints;
    final percentage = totalPoints > 0
        ? ((_score / totalPoints) * 100).toStringAsFixed(1)
        : '0.0';
    final isGood = double.parse(percentage) >= 60;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isGood ? '🏆' : '💪',
                    style: const TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isGood ? 'Fantastic!' : 'Good try!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your Score',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_score',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: isGood
                                ? AppTheme.answerGreen
                                : AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'out of $totalPoints',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: _score / math.max(totalPoints, 1),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.answerBlue,
                                    AppTheme.answerGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: isGood
                                ? AppTheme.answerGreen
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.hotPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        ),
                      ),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Circular timer arc painter ──────────────────────────────────────────────
class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerArcPainter old) =>
      old.progress != progress || old.color != color;
}
