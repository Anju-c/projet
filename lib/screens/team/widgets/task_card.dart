import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../task/edit_task_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({
    Key? key,
    required this.task,
  }) : super(key: key);

  String _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return '#FFE0E0';
      case TaskStatus.inProgress:
        return '#E0F4FF';
      case TaskStatus.done:
        return '#E0FFE0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTaskScreen(
                task: task,
                teamId: task.teamId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text('Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await taskProvider.deleteTask(task.id, task.teamId);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(_getStatusColor(task.status).substring(1, 7), radix: 16) + 0xFF000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.toString().split('.').last,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    'Due: ${task.dueDate.toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (task.assignedTo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Assigned to: ${task.assignedTo}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
