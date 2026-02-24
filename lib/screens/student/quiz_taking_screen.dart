import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/services/session_service.dart';

/// Live Quiz Taking Screen for students to answer questions
class QuizTakingScreen extends StatefulWidget {
  final Session session;
  final Quiz quiz;

  const QuizTakingScreen({
    required this.session,
    required this.quiz,
    super.key,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late List<String?> _selectedAnswers;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  int _score = 0;
  bool _quizCompleted = false;
  int _timeRemaining = 0;
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<String?>.filled(widget.quiz.questions.length, null);
    _startTimer();
  }

  void _startTimer() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    _timeRemaining = currentQuestion.timeLimit;

    _timerStream = Stream.periodic(const Duration(seconds: 1), (count) {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        _nextQuestion();
      }
      return _timeRemaining;
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _startTimer();
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _startTimer();
      });
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    try {
      // Calculate score
      int score = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        final question = widget.quiz.questions[i];
        if (_selectedAnswers[i]?.toUpperCase() ==
            question.correctAnswer.toUpperCase()) {
          score += question.points;
        }
      }

      setState(() {
        _score = score;
        _quizCompleted = true;
      });

      // Submit to session
      await SessionService().submitAnswer(
        sessionId: widget.session.id,
        studentId: '', // Get from AuthProvider
        answers: _selectedAnswers,
        score: score,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return _buildResults();
    }

    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.primaryColor,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: StreamBuilder<int>(
                  stream: _timerStream,
                  initialData: currentQuestion.timeLimit,
                  builder: (context, snapshot) {
                    final remaining = snapshot.data ?? 0;
                    final color = remaining <= 10
                        ? Colors.red
                        : remaining <= 20
                        ? Colors.orange
                        : Colors.white;
                    return Text(
                      '${remaining}s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            Container(
              height: 8,
              color: Colors.grey[200],
              child: LinearProgressIndicator(
                value:
                    (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            // Question counter
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${currentQuestion.points} points',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.questionText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    if (currentQuestion.type == 'multiple_choice')
                      _buildMultipleChoice(currentQuestion)
                    else if (currentQuestion.type == 'true_false')
                      _buildTrueFalse(currentQuestion)
                    else
                      _buildShortAnswer(currentQuestion),
                  ],
                ),
              ),
            ),
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentQuestionIndex > 0
                              ? _previousQuestion
                              : null,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _currentQuestionIndex <
                                  widget.quiz.questions.length - 1
                              ? _nextQuestion
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentQuestionIndex == widget.quiz.questions.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Quiz'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(Question question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = _selectedAnswers[_currentQuestionIndex] == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectAnswer(option),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(option)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(Question question) {
    return Column(
      children: ['True', 'False'].asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = _selectedAnswers[_currentQuestionIndex] == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectAnswer(option),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.white,
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortAnswer(Question question) {
    return TextField(
      onChanged: _selectAnswer,
      decoration: InputDecoration(
        hintText: 'Type your answer here',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildResults() {
    final totalPoints = widget.quiz.totalPoints;
    final percentage = ((_score / totalPoints) * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Completed'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Quiz Submitted!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_score / $totalPoints',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$percentage%',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
