import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class TaskProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider(this._supabaseService);

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTasksByTeam(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _supabaseService.getTeamTasks(teamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel?> createTask({
    required String teamId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    String? assignedTo,
  }) async {
    try {
      final task = await _supabaseService.createTask(
        teamId: teamId,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        assignedTo: assignedTo,
      );
      _tasks.add(task);
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<TaskModel?> updateTask({
    required String taskId,
    required String teamId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? assignedTo,
  }) async {
    try {
      final task = await _supabaseService.updateTask(
        taskId: taskId,
        teamId: teamId,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        assignedTo: assignedTo,
      );
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTask(String taskId, String teamId) async {
    try {
      await _supabaseService.deleteTask(taskId, teamId);
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<TaskModel?> addComment({
    required String taskId,
    required String teamId,
    required String content,
    required String userId,
  }) async {
    try {
      final updatedTask = await _supabaseService.addComment(
        taskId: taskId,
        teamId: teamId,
        content: content,
        userId: userId,
      );
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return updatedTask;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Alias for fetchTasksByTeam to maintain compatibility
  Future<void> loadTeamTasks(String teamId) => fetchTasksByTeam(teamId);
}