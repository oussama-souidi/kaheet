import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';

/// Student dashboard for joining sessions and viewing history
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _sessionCodeController = TextEditingController();

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome section
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryColor,
                    AppTheme.secondaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Text(
                        'Hi, ${auth.currentUser?.name.split(' ').first ?? 'Student'}!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join a quiz session and compete with classmates',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Join session section
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join a Quiz',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  TextField(
                    controller: _sessionCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter session code',
                      labelText: 'Session Code',
                      prefixIcon: const Icon(Icons.code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  ElevatedButton.icon(
                    onPressed: _handleJoinSession,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Join Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            // Quiz History section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingL,
                vertical: AppTheme.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Quizzes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  // Placeholder - replace with SessionService stream
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 50,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No quiz history yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join a session to get started',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingXL),
          ],
        ),
      ),
    );
  }

  void _handleJoinSession() {
    final sessionCode = _sessionCodeController.text.trim();
    if (sessionCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a session code')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joining session feature coming soon!')),
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
    }
  }
}
