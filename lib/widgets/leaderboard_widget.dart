import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_application_1/widgets/leaderboard_tile.dart';

/// Real-time leaderboard backed by a Firestore stream.
///
/// Pass [currentUserId] to highlight the current student's row.
class LeaderboardWidget extends StatelessWidget {
  final String sessionId;
  final String? currentUserId;

  const LeaderboardWidget({
    required this.sessionId,
    this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionParticipant>>(
      stream: SessionService().getParticipantsStream(sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final participants = snapshot.data ?? [];

        if (participants.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No participants yet',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Leaderboard',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${participants.length} player${participants.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tiles
            ...participants.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final p = entry.value;
              return LeaderboardTile(
                rank: rank,
                name: p.displayName,
                score: p.currentScore,
                correctAnswers: p.correctAnswers,
                isCurrentUser: p.userId == currentUserId,
              );
            }),
          ],
        );
      },
    );
  }
}
