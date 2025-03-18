import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import 'task/task_list_screen.dart';
import 'edit_team_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamModel team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('No user found'));
    }

    final bool isOwner = widget.team.createdby == currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.teamname),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTeamScreen(
                      teamid: widget.team.teamid,
                      teamname: widget.team.teamname,
                      teamcode: widget.team.teamcode,
                      status: widget.team.status,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _isLoading ? null : _leaveTeam,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Code: ${widget.team.teamcode}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${widget.team.status}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Members',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<UserModel>>(
                            future: teamProvider.getTeamMembers(widget.team.teamid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              final members = snapshot.data ?? [];

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(member.name[0].toUpperCase()),
                                    ),
                                    title: Text(member.name),
                                    subtitle: Text(member.email),
                                    trailing: Text(
                                      member.role=='teacher'?'Teacher':'Student',
                                      style: TextStyle(
                                        color: member.role=='teacher'
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskListScreen(
                              teamId: widget.team.teamid
                            ),
                          ),
                        );
                      },
                      child: const Text('View Tasks'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _leaveTeam() async {
    setState(() => _isLoading = true);

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      await teamProvider.leaveTeam(
        teamid: widget.team.teamid,
        userId: currentUser.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving team: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
