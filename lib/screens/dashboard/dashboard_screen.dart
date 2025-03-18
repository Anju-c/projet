import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/task_provider.dart';
import '../team/create_team_screen.dart';
import 'widgets/team_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeDashboard();
  });
  }

  Future<void> _initializeDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    await authProvider.loadCurrentUser(); // ✅ Must run first
    final user = authProvider.currentUser;

    if (user != null) {
      await teamProvider.loadTeams(user.id, user.role); // ✅ Safe now
    } else {
      print("⚠️ User is null — not logged in");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final userId =Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role ?? 'student';
      if (userId == null) {
        print('User ID is null.'); // Debug statement
        throw Exception('User not logged in');
      }

      await teamProvider.loadTeams(userId,role );
      print('Loaded teams for user ID: $userId'); // Debug statement
      for (final team in teamProvider.teams) {
        await taskProvider.loadTeamTasks(team.teamid);
      }
    } catch (e) {
      _error = 'Error loading teams: $e';
      print(_error); // Debug statement
      setState(() {});
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final isTeacher = authProvider.currentUser?.role == 'teacher'
;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTeams),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadTeams,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Teams',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (isTeacher | !isTeacher)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const CreateTeamScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Team'),
                            ),
                        ],
                      ),
                    ),
                    if (teamProvider.teams.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            isTeacher
                                ? 'Create your first team to get started!'
                                : 'Join a team to get started!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teamProvider.teams.length,
                        itemBuilder: (context, index) {
                          final team = teamProvider.teams[index];
                          return TeamCard(team: team, isTeacher: isTeacher);
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}
