import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_application_1/services/quiz_service.dart';
import 'package:flutter_application_1/screens/student/quiz_taking_screen.dart';

/// Join Session screen — Kahoot-style large game PIN entry
class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final _pinController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    final pin = _pinController.text.trim().toUpperCase();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid game PIN')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final studentId = authProvider.currentUser?.id ?? '';
      if (studentId.isEmpty) throw Exception('Not authenticated');

      // Use PIN-based lookup ← fixed bug
      final session = await SessionService().getSessionByPin(pin);
      if (session == null) {
        throw Exception('No active session found with PIN "$pin".');
      }

      await SessionService().joinSession(
        sessionId: session.id,
        userId: studentId,
      );

      final quiz = await QuizService().getQuiz(session.quizId);
      if (quiz == null) throw Exception('Quiz not found');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizTakingScreen(
              session: session,
              quiz: quiz,
              studentId: studentId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.answerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Back button ─────────────────────────────
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              // ── Logo + headline ─────────────────────────
              const Text('🎮', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Enter Game PIN!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ask your teacher for the PIN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // ── PIN card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // PIN input
                      TextField(
                        controller: _pinController,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '······',
                          hintStyle: TextStyle(
                            fontSize: 36,
                            color: Colors.grey.shade300,
                            letterSpacing: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0D0FF),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0D0FF),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        onSubmitted: (_) => _joinSession(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isJoining ? null : _joinSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.hotPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusL,
                              ),
                            ),
                          ),
                          child: _isJoining
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
                                  "Let's Go!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // ── Color dots ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(AppTheme.answerRed, '▲'),
                  const SizedBox(width: 10),
                  _dot(AppTheme.answerBlue, '◆'),
                  const SizedBox(width: 10),
                  _dot(AppTheme.answerYellow, '●'),
                  const SizedBox(width: 10),
                  _dot(AppTheme.answerGreen, '■'),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, String symbol) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          symbol,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
