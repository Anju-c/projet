import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // Auth Methods
  Future<UserModel> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final response =
        await _client
            .from('users')
            .select('*, role') // Include role in the select statement
            .eq('userid', user.id)
            .single();

    return UserModel.fromJson(response);
  }

  Future<List<UserModel>> getUsers() async {
    final response = await _client.from('users').select();

    return response.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    return getCurrentUser();
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign up');
    }

    await _client.from('users').insert({
      'userid': response.user!.id,
      'email': email,
      'name': name,
      'role': role,
    });

    return getCurrentUser();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String role,
  }) async {
    await _client
        .from('users')
        .update({'name': name, 'role': role})
        .eq('id', userId);

    return getCurrentUser();
  }

  // Team Methods
  Future<List<TeamModel>> getUserTeams(String userId, String role) async {
    // 1. Fetch all teams
    final allTeamsResponse = await _client.from('teams').select('*');
    // Optional: newest first
    Set<String> joinedTeamIds = {};
    // 2. Fetch the team the user has joined (should be at most 1 for student)
    if (role == 'student') {
      final joinedTeamResponse = await _client
          .from('team_members')
          .select('teamid')
          .eq('userid', userId);

      joinedTeamIds =
          joinedTeamResponse.map((e) => e['teamid'] as String).toSet();
    }
    // Map each team, set hasJoined flag

    return (allTeamsResponse as List).map((team) {
      final isJoined = joinedTeamIds.contains(team['teamid']);
      return TeamModel.fromJson({...team, 'hasJoined': isJoined});
    }).toList();
  }

  Future<TeamModel> createTeam({
    required String teamname,
    required String teamcode,
    required String createdBy,
    required String status,
  }) async {
    final response =
        await _client
            .from('teams')
            .insert({
              'teamname': teamname,
              'teamcode': teamcode,
              'createdby': createdBy,
              'status': status,
            })
            .select()
            .single();

    // Add creator as team member
    await _client.from('team_members').insert({
      'teamid': response['teamid'],
      'userid': createdBy,
      'role': 'admin',
    });

    return TeamModel.fromJson(response);
  }

  Future<TeamModel> updateTeam({
    required String teamid,
    String? teamname,
    String? teamcode,
    String? status,
  }) async {
    final data = <String, dynamic>{
      if (teamname != null) 'teamname': teamname,
      if (teamcode != null) 'teamcode': teamcode,
      if (status != null) 'status': status,
    };

    final response =
        await _client
            .from('teams')
            .update(data)
            .eq('teamid', teamid)
            .select()
            .single();

    return TeamModel.fromJson(response);
  }

  Future<void> deleteTeam(String teamid) async {
    // Delete team members first due to foreign key constraint
    await _client.from('team_members').delete().eq('teamid', teamid);

    // Delete tasks associated with the team
    await _client.from('tasks').delete().eq('teamid', teamid);

    // Finally delete the team
    await _client.from('teams').delete().eq('teamid', teamid);
  }

  Future<void> joinTeam({
    required String teamid,
    required String userId,
    String role = 'member',
  }) async {
    await _client.from('team_members').insert({
      'teamid': teamid,
      'userid': userId,
      'role': role,
    });
  }

  Future<void> leaveTeam({
    required String teamid,
    required String userId,
  }) async {
    await _client
        .from('team_members')
        .delete()
        .eq('teamid', teamid)
        .eq('userid', userId);
  }

  Future<UserModel> getUser(String userId) async {
    final response =
        await _client
            .from('users')
            .select('*, role') // Include role in the select statement
            .eq('id', userId)
            .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser({
    required String userId,
    String? name,
    bool? isTeacher,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (isTeacher != null) 'is_teacher': isTeacher,
    };

    final response =
        await _client
            .from('users')
            .update(data)
            .eq('id', userId)
            .select()
            .single();

    return UserModel.fromJson(response);
  }

  Future<List<UserModel>> getTeamMembers(String teamId) async {
    final response = await _client
        .from('team_members')
        .select('user:users(*)')
        .eq('teamid', teamId);

    return response.map((json) => UserModel.fromJson(json['user'])).toList();
  }

  // Task Methods
  Future<List<TaskModel>> getTeamTasks(String teamId) async {
    final response = await _client.from('tasks').select().eq('teamid', teamId);

    return response.map((json) => TaskModel.fromJson(json)).toList();
  }

  Future<TaskModel> createTask({
    required String teamId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    String? assignedTo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final response =
        await _client
            .from('tasks')
            .insert({
              'teamid': teamId,
              'title': title,
              'description': description,
              'duedate': dueDate.toIso8601String(),
              'status': status.toString().split('.').last,
              'assignedto': assignedTo,
              'createdby': user.id,
            })
            .select()
            .single();

    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask({
    required String taskId,
    required String teamId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? assignedTo,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'duedate': dueDate.toIso8601String(),
      if (status != null) 'status': status.toString().split('.').last,
      if (assignedTo != null) 'assignedto': assignedTo,
    };

    final response =
        await _client
            .from('tasks')
            .update(data)
            .eq('taskid', taskId)
            .eq('teamid', teamId)
            .select()
            .single();

    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask(String taskId, String teamId) async {
    await _client
        .from('tasks')
        .delete()
        .eq('taskid', taskId)
        .eq('teamid', teamId);
  }

  Future<TaskModel> addComment({
    required String taskId,
    required String teamId,
    required String content,
    required String userId,
  }) async {
    await _client.from('comments').insert({
      'taskid': taskId,
      'teamid': teamId,
      'content': content,
      'userid': userId,
    });

    final response =
        await _client
            .from('tasks')
            .select()
            .eq('taskid', taskId)
            .eq('teamid', teamId)
            .single();

    return TaskModel.fromJson(response);
  }
}
