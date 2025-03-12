import 'package:flutter/material.dart';
import 'package:profin1/screens/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/team_provider.dart';

class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _teamCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);

      await teamProvider.joinTeam(
        teamCode: _teamCodeController.text.trim().toUpperCase(),
        userId: userProvider.user!.id,
        isTeacher: userProvider.isTeacher,
      );

      if (!mounted) return;

      await teamProvider.forceRefresh(userProvider.user!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined team'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining team: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isTeacher = userProvider.isTeacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Team')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join an Existing Team',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isTeacher
                    ? 'As a teacher, you can join multiple teams to guide students.'
                    : 'Enter the team code to join. Students can only join one team.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _teamCodeController,
                decoration: const InputDecoration(
                  labelText: 'Team Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                  hintText: 'Enter 5-character code (e.g., AB123)',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a team code';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != value.toUpperCase()) {
                    _teamCodeController.value = _teamCodeController.value
                        .copyWith(
                          text: value.toUpperCase(),
                          selection: _teamCodeController.selection,
                        );
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinTeam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                          : const Text('Join Team'),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'What to expect?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.group,
                title: 'Team Access',
                description:
                    'You\'ll get access to the team\'s tasks and members.',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                icon: Icons.task_alt,
                title: isTeacher ? 'Review Tasks' : 'Collaborate on Tasks',
                description:
                    isTeacher
                        ? 'As a teacher, you can review and provide feedback on tasks.'
                        : 'Work together with your team members on assigned tasks.',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                icon: Icons.file_present,
                title: 'Access Files',
                description: 'View and download files shared within the team.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
