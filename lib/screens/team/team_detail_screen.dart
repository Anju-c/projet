import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/team_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../team/widgets/task_card.dart';

class TeamDetailScreen extends StatelessWidget {
  final TeamModel team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Filter tasks for this team directly from the raw task data
    final List<Map<String, dynamic>> teamTasks =
        taskProvider.tasks.where((task) => task['teamid'] == team.id).toList();

    final UserModel? user = userProvider.user;

    return Scaffold(
      appBar: AppBar(title: Text('${team.name} - Tasks')),
      body: ListView.builder(
        itemCount: teamTasks.length,
        itemBuilder: (context, index) {
          final taskMap = teamTasks[index];
          // Convert to TaskModel for the TaskCard widget
          final task = TaskModel.fromMap(taskMap);
          return TaskCard(
            task: task,
            // Handle nullable user by providing a default empty user if null
            user:
                user ??
                UserModel(
                  id: '',
                  email: '',
                  name: 'Unknown User',
                  role: 'student',
                ),
            teamId: team.id,
            onTap: () {
              // Set the selected task in the provider
              taskProvider.setSelectedTask(taskMap);
              // Navigate to task detail screen
              Navigator.pushNamed(context, '/task-detail');
            },
          );
        },
      ),
    );
  }
}
