import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/theme.dart';

/// A single ranked row in the leaderboard.
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final int correctAnswers;
  final bool isCurrentUser;

  const LeaderboardTile({
    required this.rank,
    required this.name,
    required this.score,
    required this.correctAnswers,
    this.isCurrentUser = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700), // gold
      2 => const Color(0xFFC0C0C0), // silver
      3 => const Color(0xFFCD7F32), // bronze
      _ => AppTheme.textSecondary,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.accentColor.withValues(alpha: 0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: isCurrentUser
            ? Border.all(color: AppTheme.accentColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(
                    _medal(rank),
                    style: const TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Correct answers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.answerGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$correctAnswers ✓',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.answerGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Score
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            ' pts',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) => switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };
}
