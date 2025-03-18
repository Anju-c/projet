import 'package:flutter/material.dart';
import 'package:profin1/providers/auth_provider.dart';
import '../../../models/team_model.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task_model.dart';
import 'package:provider/provider.dart';
import '../../../screens/team/task/task_list_screen.dart'; // adjust the path if needed


class TeamCard extends StatelessWidget {
  final TeamModel team;
  final bool isTeacher;

  const TeamCard({
    super.key,
    required this.team,
    required this.isTeacher,
  
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks.where((task) => task.teamId == team.teamid).toList();
    final completedTasks = tasks.where((task) => task.status == TaskStatus.done).length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () { final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to view tasks.')),
    );
    return;
  }

  if (user.role == 'teacher') {
    // ✅ Teachers can view all tasks (even if they haven't joined)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskListScreen(teamId: team.teamid),
      ),
    );
  } else if (team.hasJoined) {
    // ✅ Students can only view if they joined
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskListScreen(teamId: team.teamid),
      ),
    );
  } else {
    // ❌ Students who haven't joined see this:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join this team to view tasks.')),
    );
  }},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      team.teamname,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      team.teamcode,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16.0),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedTasks of $totalTasks tasks completed',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
