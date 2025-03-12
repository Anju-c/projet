import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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
  final Logger _logger = Logger();

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

    try {
      if (userProvider.user != null) {
        _logger.i('User ID: ${userProvider.user!.id}');
        _logger.i('Is Teacher: ${userProvider.isTeacher}');

        final rawTeams = await teamProvider.getAllTeamsRaw();
        _logger.i('Raw teams count: ${rawTeams.length}');
        if (rawTeams.isNotEmpty) {
          for (var team in rawTeams) {
            _logger.i(
              'Raw team: ${team['teamname']}, Members: ${team['members']}',
            );
          }
        }

        await teamProvider.forceRefresh(userProvider.user!.id);
        await teamProvider.loadAllTeams();

        _logger.i('Loaded user teams: ${teamProvider.teams.length}');
        if (teamProvider.teams.isEmpty) {
          _logger.w('No teams loaded for this user! Checking membership...');
        } else {
          for (var team in teamProvider.teams) {
            _logger.i(
              'Team: ${team.name}, ID: ${team.id}, Members: ${team.members}',
            );
          }
        }
        _logger.i('Loaded all teams: ${teamProvider.allTeams.length}');
      } else {
        _logger.w('No user logged in!');
      }
    } catch (e) {
      _logger.e('Error loading teams: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading teams: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TeamModel> _getFilteredTeams(List<TeamModel> teams) {
    _logger.i(
      'Filtering teams. Search query: "$_searchQuery", Total teams: ${teams.length}',
    );
    if (_searchQuery.isEmpty) {
      return teams;
    }
    final filtered =
        teams
            .where(
              (team) =>
                  team.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
    _logger.i('Filtered teams: ${filtered.length}');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final isTeacher = userProvider.isTeacher;
    final displayTeams = isTeacher ? teamProvider.allTeams : teamProvider.teams;
    final filteredTeams = _getFilteredTeams(displayTeams);

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
                          _logger.i('Search query updated: $_searchQuery');
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
                                    displayTeams.isEmpty
                                        ? 'No teams yet'
                                        : 'No teams match your search',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (displayTeams.isEmpty)
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
                                  _logger.i('Rendering team: ${team.name}');
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
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final isTeacher = userProvider.isTeacher;
    final isStudent = !isTeacher;

    if (isStudent && teamProvider.teams.isNotEmpty) {
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
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTeamScreen(),
                      ),
                    );
                    if (mounted) {
                      _loadTeams();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Join a Team'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinTeamScreen(),
                      ),
                    );
                    if (mounted) {
                      _loadTeams();
                    }
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
