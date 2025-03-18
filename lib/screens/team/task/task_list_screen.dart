import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_provider.dart';
import 'create_task_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  final String teamId;

  const TaskListScreen({
    Key? key,
    required this.teamId,
  }) : super(key: key);
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.fetchTasksByTeam(widget.teamId);
  }

  Future<void> _refreshTasks() async {
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskScreen(teamId: widget.teamId),
                ),
              );
              _refreshTasks();
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${taskProvider.error}'),
                  ElevatedButton(
                    onPressed: _refreshTasks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tasks = taskProvider.tasks;
          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks found. Create a new task to get started!'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshTasks,
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(task: task);
              },
            ),
          );
        },
      ),
    );
  }
}
