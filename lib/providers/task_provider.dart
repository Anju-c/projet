import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _selectedTask;

  List<Map<String, dynamic>> get tasks => _tasks;
  Map<String, dynamic>? get selectedTask => _selectedTask;

  void setSelectedTask(Map<String, dynamic> task) {
    _selectedTask = task;
    notifyListeners();
  }

  Future<void> fetchTasksByTeam(String teamId) async {
    final response = await supabase
        .from('tasks')
        .select()
        .eq('teamid', teamId)
        .order('duedate', ascending: true);

    _tasks = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }

  Future<void> fetchTasksForUser(String userId) async {
    final response = await supabase
        .from('tasks')
        .select()
        .or('createdby.eq.$userId,assignedto.eq.$userId');

    _tasks = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }

  Future<void> fetchAllTasksForTeacher() async {
    final response = await supabase.from('tasks').select();
    _tasks = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String createdBy,
    required String assignedTo,
    required String teamId,
    required DateTime dueDate,
    required String priority,
    List<String> attachments = const [],
  }) async {
    final task = {
      'title': title,
      'description': description,
      'createdby': createdBy,
      'assignedto': assignedTo,
      'teamid': teamId,
      'duedate': dueDate.toIso8601String(),
      'priority': priority,
      'status': 'To Do',
      'attachments': attachments,
      'comments': [],
    };

    await supabase.from('tasks').insert(task);
    await fetchTasksByTeam(teamId);
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await supabase
        .from('tasks')
        .update({'status': newStatus})
        .eq('taskid', taskId);

    final updated = _tasks.firstWhere((task) => task['taskid'] == taskId);
    if (updated.isNotEmpty) {
      await fetchTasksByTeam(updated['teamid']);
    }
  }

  Future<String?> uploadFile(File file, String teamId) async {
    try {
      final ext = extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';

      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      final storageResponse = await supabase.storage
          .from('abstract')
          .uploadBinary(
            'teams/$teamId/$fileName',
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      if (storageResponse.isEmpty) {
        return null;
      }

      final publicUrl = supabase.storage
          .from('abstract')
          .getPublicUrl('teams/$teamId/$fileName');
      return publicUrl;
    } catch (e) {
      debugPrint('File upload failed: $e');
      return null;
    }
  }

  Future<void> deleteTask(String taskId, String teamId) async {
    await supabase.from('tasks').delete().eq('taskid', taskId);
    await fetchTasksByTeam(teamId);
  }

  Future<void> addComment(String taskId, String comment) async {
    final task = _tasks.firstWhere((element) => element['taskid'] == taskId);
    final comments = List<String>.from(task['comments'] ?? []);
    comments.add(comment);

    await supabase
        .from('tasks')
        .update({'comments': comments})
        .eq('taskid', taskId);
    await fetchTasksByTeam(task['teamid']);
  }

  Future<void> addAttachment(String taskId, String url) async {
    final task = _tasks.firstWhere((element) => element['taskid'] == taskId);
    final attachments = List<String>.from(task['attachments'] ?? []);
    attachments.add(url);

    await supabase
        .from('tasks')
        .update({'attachments': attachments})
        .eq('taskid', taskId);
    await fetchTasksByTeam(task['teamid']);
  }
}
