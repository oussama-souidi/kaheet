import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/services/quiz_service.dart';
import 'package:flutter_application_1/utils/constants.dart';
import 'package:uuid/uuid.dart';

/// Create Quiz Screen for professors to create new quizzes
class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Question> _questions = [];
  bool _isLoading = false;
  int _currentStep = 0; // 0: Quiz Info, 1: Add Questions

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionScreen(
          onQuestionAdded: (question) {
            setState(() => _questions.add(question));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Question added (${_questions.length})'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }

  void _editQuestion(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionScreen(
          initialQuestion: _questions[index],
          onQuestionAdded: (question) {
            setState(() => _questions[index] = question);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Question updated'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Question deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    // Form is already validated when user clicked "Next: Add Questions"
    // Just check if questions are added
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final professorId = authProvider.currentUser?.id ?? '';

      if (professorId.isEmpty) {
        throw Exception('Professor ID not found');
      }

      // Calculate total points
      final totalPoints = _questions.fold<int>(
        0,
        (sum, question) => sum + question.points,
      );

      final quiz = Quiz(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        professorId: professorId,
        questions: _questions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: false,
        totalPoints: totalPoints,
      );

      await QuizService().createQuiz(
        title: quiz.title,
        description: quiz.description,
        professorId: quiz.professorId,
        questions: quiz.questions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _currentStep == 0 ? _buildQuizInfoStep() : _buildQuestionsStep(),
    );
  }

  Widget _buildQuizInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'Enter quiz title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter quiz title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Quiz Description',
                hintText: 'Enter quiz description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter quiz description';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next: Add Questions',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsStep() {
    return Column(
      children: [
        Expanded(
          child: _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No questions yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add questions to your quiz',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(question.questionText),
                        subtitle: Text(question.type),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => _editQuestion(index),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _deleteQuestion(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Quiz'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Add/Edit Question Screen
class AddQuestionScreen extends StatefulWidget {
  final Function(Question) onQuestionAdded;
  final Question? initialQuestion;

  const AddQuestionScreen({
    required this.onQuestionAdded,
    this.initialQuestion,
    super.key,
  });

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _correctAnswerController;

  String _selectedType = AppConstants.questionTypeMultipleChoice;
  int _timeLimit = 30;
  int _points = 10;

  @override
  void initState() {
    super.initState();
    final question = widget.initialQuestion;

    _questionController = TextEditingController(
      text: question?.questionText ?? '',
    );
    _explanationController = TextEditingController(
      text: question?.explanation ?? '',
    );
    _correctAnswerController = TextEditingController(
      text: question?.correctAnswer ?? '',
    );
    _selectedType = question?.type ?? AppConstants.questionTypeMultipleChoice;
    _timeLimit = question?.timeLimit ?? 30;
    _points = question?.points ?? 10;

    _optionControllers = (question?.options ?? ['', '', '', ''])
        .map((option) => TextEditingController(text: option))
        .toList();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _correctAnswerController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text')),
      );
      return;
    }

    if (_selectedType == AppConstants.questionTypeMultipleChoice) {
      if (_optionControllers.any((c) => c.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all options')),
        );
        return;
      }
    }

    if (_correctAnswerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter correct answer')),
      );
      return;
    }

    final question = Question(
      id: widget.initialQuestion?.id ?? const Uuid().v4(),
      questionText: _questionController.text.trim(),
      type: _selectedType,
      options: _selectedType == AppConstants.questionTypeMultipleChoice
          ? _optionControllers.map((c) => c.text.trim()).toList()
          : [],
      correctAnswer: _correctAnswerController.text.trim(),
      timeLimit: _timeLimit,
      explanation: _explanationController.text.trim(),
      points: _points,
    );

    widget.onQuestionAdded(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Question'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: [
                DropdownMenuItem(
                  value: AppConstants.questionTypeMultipleChoice,
                  child: const Text('Multiple Choice'),
                ),
                DropdownMenuItem(
                  value: AppConstants.questionTypeTrueFalse,
                  child: const Text('True/False'),
                ),
                DropdownMenuItem(
                  value: AppConstants.questionTypeShortAnswer,
                  child: const Text('Short Answer'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Question Text',
                hintText: 'Enter your question',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            if (_selectedType == AppConstants.questionTypeMultipleChoice)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._optionControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            TextField(
              controller: _correctAnswerController,
              decoration: InputDecoration(
                labelText: 'Correct Answer',
                hintText: 'Enter correct answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: 'Explanation (Optional)',
                hintText: 'Explain the correct answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Limit (seconds)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Slider(
                        value: _timeLimit.toDouble(),
                        min: 10,
                        max: 300,
                        onChanged: (value) =>
                            setState(() => _timeLimit = value.toInt()),
                      ),
                      Text('$_timeLimit seconds'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Slider(
                        value: _points.toDouble(),
                        min: 1,
                        max: 100,
                        onChanged: (value) =>
                            setState(() => _points = value.toInt()),
                      ),
                      Text('$_points points'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
