import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/services/quiz_service.dart';
import 'package:flutter_application_1/utils/constants.dart';
import 'package:uuid/uuid.dart';

// ─── Create / Edit Quiz Screen ────────────────────────────────────────────────

/// Pass [existingQuiz] to enter edit mode.
class CreateQuizScreen extends StatefulWidget {
  final Quiz? existingQuiz;
  const CreateQuizScreen({this.existingQuiz, super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late List<Question> _questions;
  bool _isLoading = false;
  int _currentStep = 0;

  bool get _isEditing => widget.existingQuiz != null;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuiz;
    _titleController = TextEditingController(text: q?.title ?? '');
    _descriptionController = TextEditingController(text: q?.description ?? '');
    _questions = List<Question>.from(q?.questions ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─ Add / Edit question ─────────────────────────────────────────────────────

  void _openAddQuestion({Question? initial, int? editIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddQuestionScreen(
          initialQuestion: initial,
          onSaved: (question) {
            setState(() {
              if (editIndex != null) {
                _questions[editIndex] = question;
              } else {
                _questions.add(question);
              }
            });
            Navigator.pop(context);
            _showSnack(
              editIndex != null
                  ? '✅ Question updated!'
                  : '✅ Question ${_questions.length} added!',
              AppTheme.answerGreen,
            );
          },
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: const Text('Delete Question?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.answerRed,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─ Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_questions.isEmpty) {
      _showSnack('Add at least one question!', AppTheme.answerRed);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final professorId = auth.currentUser?.id ?? '';
      if (professorId.isEmpty) throw Exception('Not authenticated');

      if (_isEditing) {
        final updated = widget.existingQuiz!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          questions: _questions,
          totalPoints: _questions.fold<int>(0, (a, q) => a + q.points),
        );
        await QuizService().updateQuiz(updated);
        _showSnack('🎉 Quiz updated!', AppTheme.answerGreen);
      } else {
        await QuizService().createQuiz(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          professorId: professorId,
          questions: _questions,
        );
        _showSnack('🎉 Quiz created!', AppTheme.answerGreen);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: $e', AppTheme.answerRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─ Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? (_isEditing ? 'Edit Quiz Info' : 'Quiz Info')
              : 'Questions',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: AppTheme.surfaceLight,
      body: _currentStep == 0 ? _buildInfoStep() : _buildQuestionsStep(),
    );
  }

  // Step 1 ───────────────────────────────────────────────────────────────────

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepBadge(
              'Step 1 of 2',
              'Quiz Information',
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            _card(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      hintText: 'e.g. "World History Quiz"',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is this quiz about?',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Enter a description'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _currentStep = 1);
                  }
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text('Next: Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2 ───────────────────────────────────────────────────────────────────

  Widget _buildQuestionsStep() {
    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: _stepBadge(
            'Step 2 of 2',
            '${_questions.length} question${_questions.length == 1 ? '' : 's'}',
            AppTheme.answerBlue,
          ),
        ),
        // Drag-to-reorder list
        Expanded(
          child: _questions.isEmpty
              ? _emptyQuestionsState()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(12),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _questions.removeAt(oldIndex);
                      _questions.insert(newIndex, item);
                    });
                  },
                  itemCount: _questions.length,
                  itemBuilder: (context, index) => _questionCard(index),
                ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _emptyQuestionsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first question',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _questionCard(int index) {
    final question = _questions[index];
    const colors = [
      AppTheme.answerRed,
      AppTheme.answerBlue,
      AppTheme.answerYellow,
      AppTheme.answerGreen,
    ];
    final color = colors[index % 4];

    return Container(
      key: ValueKey(question.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color stripe
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusL),
                bottomLeft: Radius.circular(AppTheme.radiusL),
              ),
            ),
          ),
          // Drag handle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.drag_handle, color: Color(0xFFCCBBEE), size: 20),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${question.points} pts • ${question.timeLimit}s • ${question.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                _openAddQuestion(initial: question, editIndex: index);
              }
              if (v == 'delete') _deleteQuestion(index);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openAddQuestion(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.answerGreen,
                    minimumSize: const Size(0, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes ✅' : 'Save Quiz 🎉',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─ Helpers ─────────────────────────────────────────────────────────────────

  Widget _stepBadge(String step, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Add / Edit Question Screen ───────────────────────────────────────────────

class AddQuestionScreen extends StatefulWidget {
  final Function(Question) onSaved;
  final Question? initialQuestion;

  const AddQuestionScreen({
    required this.onSaved,
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
  late String _selectedType;
  int _timeLimit = 30;
  int _points = 10;
  int _correctOptionIndex = 0; // which option is the correct answer

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
    final q = widget.initialQuestion;
    _questionController = TextEditingController(text: q?.questionText ?? '');
    _explanationController = TextEditingController(text: q?.explanation ?? '');
    _selectedType = q?.type ?? AppConstants.questionTypeMultipleChoice;
    _timeLimit = q?.timeLimit ?? 30;
    _points = q?.points ?? 10;
    _optionControllers =
        (q?.options.isNotEmpty == true ? q!.options : ['', '', '', ''])
            .map((o) => TextEditingController(text: o))
            .toList();

    // Find correct option index from existing question
    if (q != null) {
      if (_selectedType == AppConstants.questionTypeMultipleChoice) {
        final idx = q.options.indexWhere(
          (o) => o.toLowerCase() == q.correctAnswer.toLowerCase(),
        );
        _correctOptionIndex = idx >= 0 ? idx : 0;
      } else if (_selectedType == AppConstants.questionTypeTrueFalse) {
        _correctOptionIndex = q.correctAnswer == 'True' ? 0 : 1;
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _correctOptionIndex = 0;
    });
  }

  String get _correctAnswer {
    switch (_selectedType) {
      case AppConstants.questionTypeMultipleChoice:
        return _optionControllers[_correctOptionIndex].text.trim();
      case AppConstants.questionTypeTrueFalse:
        return _correctOptionIndex == 0 ? 'True' : 'False';
      default:
        return _optionControllers.first.text
            .trim(); // short answer: direct text field
    }
  }

  void _saveQuestion() {
    if (_questionController.text.trim().isEmpty) {
      _showSnack('Enter the question text');
      return;
    }
    if (_selectedType == AppConstants.questionTypeMultipleChoice) {
      if (_optionControllers.any((c) => c.text.trim().isEmpty)) {
        _showSnack('Fill in all answer options');
        return;
      }
      if (_optionControllers[_correctOptionIndex].text.trim().isEmpty) {
        _showSnack('Select a non-empty correct answer');
        return;
      }
    }
    if (_selectedType == AppConstants.questionTypeShortAnswer &&
        _correctAnswer.isEmpty) {
      _showSnack('Enter the expected answer');
      return;
    }

    widget.onSaved(
      Question(
        id: widget.initialQuestion?.id ?? const Uuid().v4(),
        questionText: _questionController.text.trim(),
        type: _selectedType,
        options: _selectedType == AppConstants.questionTypeMultipleChoice
            ? _optionControllers.map((c) => c.text.trim()).toList()
            : _selectedType == AppConstants.questionTypeTrueFalse
            ? ['True', 'False']
            : [],
        correctAnswer: _correctAnswer,
        timeLimit: _timeLimit,
        explanation: _explanationController.text.trim(),
        points: _points,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialQuestion == null ? 'Add Question' : 'Edit Question',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.surfaceLight,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Question Type'),
                  const SizedBox(height: 8),
                  _typeSelector(),
                  const SizedBox(height: 20),
                  _sectionLabel('Question'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'Type your question here…',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  // ─ Answer section by type ──────────────────────────────
                  if (_selectedType ==
                      AppConstants.questionTypeMultipleChoice) ...[
                    _sectionLabel('Answer Options'),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the checkmark to mark the correct answer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._optionControllers.asMap().entries.map(
                      (e) => _multipleChoiceOption(e.key),
                    ),
                  ],
                  if (_selectedType == AppConstants.questionTypeTrueFalse) ...[
                    _sectionLabel('Correct Answer'),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the option that is correct',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _trueFalseSelector(),
                  ],
                  if (_selectedType ==
                      AppConstants.questionTypeShortAnswer) ...[
                    _sectionLabel('Expected Answer (for reference)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _optionControllers.first,
                      decoration: InputDecoration(
                        hintText: 'Sample correct answer…',
                        fillColor: AppTheme.answerGreen.withValues(alpha: 0.05),
                        filled: true,
                        prefixIcon: const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.answerGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.answerYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.answerYellow.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.answerYellow,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Short answers are graded manually by the teacher after the session ends.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('Explanation (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _explanationController,
                    decoration: const InputDecoration(
                      hintText: 'Explain why this is correct…',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  _settingSlider(
                    label: 'Time Limit',
                    value: _timeLimit.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 11,
                    displayValue: '${_timeLimit}s',
                    color: AppTheme.answerBlue,
                    onChanged: (v) => setState(() => _timeLimit = v.toInt()),
                  ),
                  const SizedBox(height: 16),
                  _settingSlider(
                    label: 'Points',
                    value: _points.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    displayValue: '$_points pts',
                    color: AppTheme.answerYellow,
                    onChanged: (v) => setState(() => _points = v.toInt()),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.answerGreen,
                ),
                child: const Text(
                  'Save Question ✅',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─ Multiple choice option row ────────────────────────────────────────────

  Widget _multipleChoiceOption(int index) {
    final isCorrect = _correctOptionIndex == index;
    final color = _colors[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Color symbol box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _symbols[index],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: TextField(
              controller: _optionControllers[index],
              onChanged: (_) => setState(() {}), // refresh display
              decoration: InputDecoration(
                hintText: 'Option ${index + 1}',
                fillColor: isCorrect
                    ? AppTheme.answerGreen.withValues(alpha: 0.06)
                    : Colors.white,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide(
                    color: isCorrect
                        ? AppTheme.answerGreen
                        : const Color(0xFFE0D0FF),
                    width: isCorrect ? 2 : 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide(
                    color: isCorrect
                        ? AppTheme.answerGreen
                        : AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Correct answer toggle
          GestureDetector(
            onTap: () => setState(() => _correctOptionIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCorrect ? AppTheme.answerGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect
                      ? AppTheme.answerGreen
                      : const Color(0xFFCCBBEE),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: isCorrect ? Colors.white : const Color(0xFFCCBBEE),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─ True / False selector ─────────────────────────────────────────────────

  Widget _trueFalseSelector() {
    return Row(
      children: [
        Expanded(child: _tfTile('True', 0, AppTheme.answerGreen, '✔')),
        const SizedBox(width: 12),
        Expanded(child: _tfTile('False', 1, AppTheme.answerRed, '✖')),
      ],
    );
  }

  Widget _tfTile(String label, int index, Color color, String icon) {
    final isSelected = _correctOptionIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _correctOptionIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 22,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─ Type selector ─────────────────────────────────────────────────────────

  Widget _typeSelector() {
    return Row(
      children: [
        _typeChip(
          AppConstants.questionTypeMultipleChoice,
          'Multiple Choice',
          Icons.check_box_outlined,
        ),
        const SizedBox(width: 8),
        _typeChip(
          AppConstants.questionTypeTrueFalse,
          'True / False',
          Icons.toggle_on_outlined,
        ),
        const SizedBox(width: 8),
        _typeChip(
          AppConstants.questionTypeShortAnswer,
          'Short Answer',
          Icons.edit_outlined,
        ),
      ],
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : const Color(0xFFE0D0FF),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─ Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _settingSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
