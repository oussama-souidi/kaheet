import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/quiz.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_application_1/screens/student/quiz_taking_screen.dart';

/// Student Lobby Screen — shown while waiting for the teacher to start the quiz.
/// Displays the list of joined students and session PIN.
class StudentLobbyScreen extends StatefulWidget {
  final Session session;
  final Quiz quiz;
  final String studentId;
  final String studentName;

  const StudentLobbyScreen({
    required this.session,
    required this.quiz,
    required this.studentId,
    required this.studentName,
    super.key,
  });

  @override
  State<StudentLobbyScreen> createState() => _StudentLobbyScreenState();
}

class _StudentLobbyScreenState extends State<StudentLobbyScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Session?>? _sessionSub;
  StreamSubscription<List<SessionParticipant>>? _participantsSub;
  List<SessionParticipant> _participants = [];
  bool _navigated = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for participants joining
    _participantsSub = SessionService()
        .getParticipantsStream(widget.session.id)
        .listen((participants) {
          if (mounted) setState(() => _participants = participants);
        });

    // Listen for session status changes
    _sessionSub = SessionService()
        .getSessionStream(widget.session.id)
        .listen(_onSessionUpdate);
  }

  void _onSessionUpdate(Session? session) {
    if (session == null || !mounted || _navigated) return;

    // Teacher cancelled — go back
    if (session.status == 'cancelled') {
      _navigated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session was cancelled by the teacher.'),
          backgroundColor: AppTheme.answerRed,
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }

    // Teacher pressed Start Quiz — navigate to quiz taking screen
    if (session.status == 'question_active') {
      _navigated = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizTakingScreen(
            session: session,
            quiz: widget.quiz,
            studentId: widget.studentId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _participantsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.key,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PIN: ${widget.session.pin}',
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_participants.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Quiz title + waiting animation ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🎮', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.quiz.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.hotPink,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'You\'re in! Hi, ${widget.studentName} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Waiting for teacher to start quiz...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Participants list ──────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Players in lobby',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.hotPink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_participants.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          Expanded(
                            child: _participants.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Be the first to join! 🎉',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    itemCount: _participants.length,
                                    itemBuilder: (context, index) {
                                      final p = _participants[index];
                                      final isMe = p.userId == widget.studentId;
                                      const avatarColors = [
                                        AppTheme.answerRed,
                                        AppTheme.answerBlue,
                                        AppTheme.answerYellow,
                                        AppTheme.answerGreen,
                                        AppTheme.hotPink,
                                      ];
                                      final avatarColor =
                                          avatarColors[index %
                                              avatarColors.length];
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.white.withValues(
                                                  alpha: 0.25,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM,
                                          ),
                                          border: isMe
                                              ? Border.all(
                                                  color: Colors.white54,
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: avatarColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  p.displayName
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                isMe
                                                    ? '${p.displayName} (You)'
                                                    : p.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (isMe)
                                              const Icon(
                                                Icons.person,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom loading indicator ───────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Get ready! Quiz has ${widget.quiz.questions.length} questions',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
