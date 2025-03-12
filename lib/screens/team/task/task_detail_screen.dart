import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../providers/user_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../models/file_model.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _updateTaskStatus(String status) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final task = taskProvider.selectedTask;

    if (userProvider.isTeacher &&
        !teamProvider.teams.any((t) => t.id == task!['teamid'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join the team to provide feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (task != null) {
        await taskProvider.updateTaskStatus(task['taskid'], status);

        if (status == 'rejected' &&
            _feedbackController.text.trim().isNotEmpty) {
          await taskProvider.addComment(
            task['taskid'],
            _feedbackController.text.trim(),
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: ${e.toString()}'),
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

  Future<void> _approveAbstract() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final task = taskProvider.selectedTask;

    if (task == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await teamProvider.approveAbstract(task['teamid']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abstract approved, team status set to accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving abstract: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = taskProvider.selectedTask;

    if (task == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;

        setState(() {
          _isLoading = true;
        });

        final fileUrl = await taskProvider.uploadFile(file, task['teamid']);

        if (fileUrl != null) {
          await taskProvider.addAttachment(task['taskid'], fileUrl);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: ${e.toString()}'),
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

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Provide Feedback'),
            content: TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Enter feedback for the student',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateTaskStatus('rejected');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject with Feedback'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final task = taskProvider.selectedTask;
    final isTeacher = userProvider.isTeacher;

    if (task == null) {
      return const Scaffold(body: Center(child: Text('No task selected')));
    }

    final List<FileModel> files = [];
    if (task['attachments'] != null && task['attachments'] is List) {
      for (var attachment in task['attachments']) {
        files.add(
          FileModel(
            fileName: attachment.split('/').last,
            filePath: attachment,
            uploadedAt: DateTime.now(),
            uploadedBy: task['assignedto'],
          ),
        );
      }
    }

    final bool isOverdue =
        DateTime.parse(task['duedate']).isBefore(DateTime.now()) &&
        task['status'] != 'done' &&
        task['status'] != 'accepted';

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(task['status']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              task['description'],
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.person,
                              title: 'Assigned To',
                              value: task['assignedto'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              title: 'Deadline',
                              value: DateFormat(
                                'MMMM dd, yyyy',
                              ).format(DateTime.parse(task['duedate'])),
                              isHighlighted: isOverdue,
                            ),
                            if (task['updated_at'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.update,
                                title: 'Last Updated',
                                value: DateFormat(
                                  'MMMM dd, yyyy',
                                ).format(DateTime.parse(task['updated_at'])),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (task['comments'] != null &&
                        task['comments'].isNotEmpty) ...[
                      Card(
                        color:
                            task['status'] == 'rejected'
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    task['status'] == 'rejected'
                                        ? Icons.feedback
                                        : Icons.check_circle,
                                    color:
                                        task['status'] == 'rejected'
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    task['status'] == 'rejected'
                                        ? 'Teacher Feedback'
                                        : 'Approval Notes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          task['status'] == 'rejected'
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                task['comments'].isString
                                    ? task['comments']
                                    : (task['comments'] is List &&
                                            task['comments'].isNotEmpty
                                        ? task['comments'].join('\n')
                                        : ''),
                                style: TextStyle(
                                  color:
                                      task['status'] == 'rejected'
                                          ? Colors.red.shade800
                                          : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Attached Files',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!isTeacher && task['status'] != 'accepted')
                                  ElevatedButton.icon(
                                    onPressed: _uploadFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (files.isEmpty)
                              const Text('No files attached yet'),
                            ...files.map((file) => _buildFileItem(file)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isTeacher &&
                        task['status'] != 'accepted' &&
                        task['status'] != 'rejected') ...[
                      Row(
                        children: [
                          if (task['status'] == 'todo')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _updateTaskStatus('in_progress'),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          if (task['status'] == 'in_progress') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateTaskStatus('done'),
                                icon: const Icon(Icons.check),
                                label: const Text('Mark as Done'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (isTeacher && task['status'] == 'done') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateTaskStatus('accepted'),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showFeedbackDialog,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _approveAbstract,
                        icon: const Icon(Icons.approval),
                        label: const Text('Approve Abstract'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'todo':
        color = Colors.grey;
        text = 'To Do';
        break;
      case 'in_progress':
        color = Colors.blue;
        text = 'In Progress';
        break;
      case 'done':
        color = Colors.green;
        text = 'Done';
        break;
      case 'accepted':
        color = Colors.purple;
        text = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? Colors.red : Colors.deepPurple,
        ),
        const SizedBox(width: 8),
        Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isHighlighted ? Colors.red : Colors.grey.shade700,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(FileModel file) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(file.fileName),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(file.uploadedAt)),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File URL: ${file.filePath}')));
        },
      ),
    );
  }
}
