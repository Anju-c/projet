import 'package:flutter/material.dart';
import 'package:profin1/screens/team/task/task_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team_model.dart';
import '../team/create_team_screen.dart';
import '../team/join_team_screen.dart';
import 'widgets/team_card.dart';
import 'widgets/sprint_progress_chart.dart';
import '../landing_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    if (userProvider.user != null) {
      await teamProvider.loadUserTeams(userProvider.user!.id);
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<TeamModel> _getFilteredTeams(List<TeamModel> teams) {
    if (_searchQuery.isEmpty) {
      return teams;
    }

    return teams
        .where(
          (team) =>
              team.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final filteredTeams = _getFilteredTeams(teamProvider.teams);
    final isTeacher = userProvider.isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await userProvider.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search teams...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  if (isTeacher && teamProvider.teams.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sprint Progress Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: SprintProgressChart(
                                  teams: teamProvider.teams,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child:
                        filteredTeams.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.group_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    teamProvider.teams.isEmpty
                                        ? 'No teams yet'
                                        : 'No teams match your search',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (teamProvider.teams.isEmpty)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                        isTeacher
                                            ? 'Join a Team'
                                            : 'Create or Join a Team',
                                      ),
                                      onPressed: () {
                                        _showTeamActionDialog(context);
                                      },
                                    ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: _loadTeams,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredTeams.length,
                                itemBuilder: (context, index) {
                                  final team = filteredTeams[index];
                                  return TeamCard(
                                    team: team,
                                    onTap: () {
                                      teamProvider.selectTeam(team.id);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const TaskDetailScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTeamActionDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTeamActionDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isTeacher = userProvider.isTeacher;
    final isStudent = !isTeacher;

    // Students can only join one team
    if (isStudent &&
        Provider.of<TeamProvider>(context, listen: false).teams.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Students can only join one team'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Team Action'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.create),
                  title: const Text('Create a Team'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTeamScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Join a Team'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinTeamScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
