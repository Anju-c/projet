import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel user;
  final String teamId;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.teamId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(task.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${task.status}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Assigned to: ${task.assignedTo}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
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
