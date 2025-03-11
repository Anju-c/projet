import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  static const String supabaseUrl = 'https://bjtijiyjqmfphyibkpma.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdGlqaXlqcW1mcGh5aWJrcG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDU5NzAsImV4cCI6MjA1NjIyMTk3MH0.BrPFmPy39lkXQbFWjrMMbcc-AEabWTEgppaK1ddqU8k';
  
  late final SupabaseClient client;
  
  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    client = Supabase.instance.client;
    
    // Check if tables exist
    await _checkTablesExist();
  }
  
  Future<void> _checkTablesExist() async {
    try {
      print('Checking if tables exist...');
      
      // Try to query each table
      final usersResult = await client.from('users').select('count').limit(1);
      print('Users table exists: ${usersResult != null}');
      
      final teamsResult = await client.from('teams').select('count').limit(1);
      print('Teams table exists: ${teamsResult != null}');
      
      final tasksResult = await client.from('tasks').select('count').limit(1);
      print('Tasks table exists: ${tasksResult != null}');
      
      print('All tables exist and are accessible');
    } catch (e) {
      print('Error checking tables: $e');
    }
  }
  
  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required bool isTeacher,
  }) async {
    try {
      print('Starting sign up process for email: $email');

      // Step 1: Create the auth user with Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': isTeacher ? 'teacher' : 'student'},
      );

      print('Auth response status: ${response.user != null ? 'Success' : 'Failed'}');

      if (response.user != null) {
        print('User ID: ${response.user!.id}');

        try {
          // Wait for auth to propagate
          await Future.delayed(const Duration(seconds: 1));

          // Create user profile without storing password
          final userData = {
            'userid': response.user!.id,
            'email': email,
            'name': name,
            'role': isTeacher ? 'teacher' : 'student',
            'accesscode': '', // Keep empty for now, will be updated when joining/creating team
          };

          print('Attempting to create user profile: $userData');

          // Try to create or update the user profile
          await client
              .from('users')
              .upsert(userData)
              .select()
              .single();
          
          print('User profile created successfully');
        } catch (dbError) {
          print('Error creating user profile in database: $dbError');
          // Don't throw here - the auth user is created, we can fix profile later
        }
      }

      return response;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // Create or update user profile
  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String email,
    required String name,
    required bool isTeacher,
  }) async {
    try {
      final userData = {
        'userid': userId,
        'email': email,
        'name': name,
        'role': isTeacher ? 'teacher' : 'student',
        'accesscode': '', // Keep empty, will be set when joining/creating team
      };

      // Try to get existing user first
      try {
        final existingUser = await client
            .from('users')
            .select()
            .eq('email', email)
            .single();
        
        // Update existing user
        return await client
            .from('users')
            .update(userData)
            .eq('email', email)
            .select()
            .single();
      } catch (e) {
        // If no user exists, create new one
        return await client
            .from('users')
            .insert(userData)
            .select()
            .single();
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // Team methods
  Future<Map<String, dynamic>> createTeam({
    required String teamName,
    required String userId,
    required bool isTeacher,
  }) async {
    try {
      // Generate a random 5-character team code
      final String teamCode = _generateTeamCode();

      // Create the team
      final teamResponse = await client
          .from('teams')
          .insert({
            'teamname': teamName,
            'teamcode': teamCode,
            'createdby': userId,
            'members': [
              {'userid': userId, 'role': isTeacher ? 'teacher' : 'student'}
            ],
          })
          .select()
          .single();

      // Update the user's accesscode with the team code
      await client
          .from('users')
          .update({'accesscode': teamCode})
          .eq('userid', userId);

      print('Team created successfully with code: $teamCode');
      return teamResponse;
    } catch (e) {
      print('Error creating team: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinTeam({
    required String teamCode,
    required String userId,
    required bool isTeacher,
  }) async {
    try {
      // Find the team with the given code
      final teamResponse = await client
          .from('teams')
          .select()
          .eq('teamcode', teamCode)
          .single();

      // Check if the user is already a member
      final members = List<Map<String, dynamic>>.from(teamResponse['members']);
      if (members.any((member) => member['userid'] == userId)) {
        throw Exception('You are already a member of this team');
      }

      // For students, ensure they're not in another team
      if (!isTeacher) {
        final currentUser = await client
            .from('users')
            .select()
            .eq('userid', userId)
            .single();
        
        if (currentUser['accesscode'] != null && 
            currentUser['accesscode'].toString().isNotEmpty) {
          throw Exception('Students can only join one team');
        }
      }

      // Add user to team members
      members.add({'userid': userId, 'role': isTeacher ? 'teacher' : 'student'});
      await client
          .from('teams')
          .update({'members': members})
          .eq('teamid', teamResponse['teamid']);

      // Update user's accesscode
      await client
          .from('users')
          .update({'accesscode': teamCode})
          .eq('userid', userId);

      print('Successfully joined team with code: $teamCode');
      return teamResponse;
    } catch (e) {
      print('Error joining team: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserTeams(String userId) async {
    final teams = await client.from('teams').select().contains('members', [
      {'userid': userId},
    ]);

    return teams.map<Map<String, dynamic>>((team) {
      final members = team['members'] as List;
      final userMember = members.firstWhere(
        (member) => member['userid'] == userId,
        orElse: () => {'role': 'student'}, // Default to student if not found
      );
      return {...team, 'is_teacher': userMember['role'] == 'teacher'};
    }).toList();
  }
  
  Future<void> updateTeamName({
    required String teamId,
    required String newName,
  }) async {
    await client.from('teams').update({
      'teamname': newName,
    }).eq('teamid', teamId);
  }
  
  // Task methods
  Future<Map<String, dynamic>> createTask({
    required String teamId,
    required String title,
    required String description,
    required String assignedTo,
    required DateTime deadline,
    String? status = 'todo',
    String? priority = 'medium',
  }) async {
    final response =
        await client
            .from('tasks')
            .insert({
              'title': title,
              'description': description,
              'assignedto': assignedTo,
              'teamid': teamId,
              'status': status,
              'duedate': deadline.toIso8601String(),
              'priority': priority ?? 'medium',
              'createdby': client.auth.currentUser!.id,
              'attachments': [],
              'comments': [],
            })
            .select('*, users!inner(*)')
            .single();

    return response;
  }
  
  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
    String? feedback,
  }) async {
    final task =
        await client
            .from('tasks')
            .select('comments')
            .eq('taskid', taskId)
            .single();
    final comments = List<Map<String, dynamic>>.from(task['comments'] as List? ?? []);

    if (feedback != null && feedback.trim().isNotEmpty) {
      comments.add({
        'userid': client.auth.currentUser!.id,
        'text': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    await client
        .from('tasks')
        .update({'status': status, 'comments': comments})
        .eq('taskid', taskId);
  }
  
  Future<List<Map<String, dynamic>>> getTeamTasks(String teamId) async {
    final tasks = await client
        .from('tasks')
        .select('*, users!inner(*)')
        .eq('teamid', teamId)
        .order('duedate');
    
    return tasks;
  }
  
  // File upload methods
  Future<String> uploadFile({
    required String teamId,
    required String taskId,
    required File file,
    required String fileName,
  }) async {
    final fileExt = fileName.split('.').last;
    final filePath = '$teamId/$taskId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    
    final response = await client.storage.from('task_files').upload(
      filePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    
    // Update the task's attachments
    final task =
        await client
            .from('tasks')
            .select('attachments')
            .eq('taskid', taskId)
            .single();
    final attachments = List<Map<String, dynamic>>.from(task['attachments'] as List? ?? []);

    attachments.add({
      'file_path': response,
      'file_name': fileName,
      'uploaded_by': client.auth.currentUser!.id,
      'uploaded_at': DateTime.now().toIso8601String(),
    });

    await client
        .from('tasks')
        .update({'attachments': attachments})
        .eq('taskid', taskId);

    return response;
  }
  
  Future<List<Map<String, dynamic>>> getTaskFiles(String taskId) async {
    final task =
        await client
            .from('tasks')
            .select('attachments')
            .eq('taskid', taskId)
            .single();
    final attachments = task['attachments'] as List? ?? [];

    return attachments
        .map<Map<String, dynamic>>(
          (attachment) => Map<String, dynamic>.from(attachment),
        )
        .toList();
  }
  
  Future<String> getFileUrl(String filePath) async {
    return client.storage.from('task_files').getPublicUrl(filePath);
  }
  
  // Helper methods
  String _generateTeamCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String result = '';
    
    for (var i = 0; i < 5; i++) {
      final randomIndex = (int.parse(random[i % random.length]) + i) % chars.length;
      result += chars[randomIndex];
    }
    
    return result;
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await client
        .from('users')
        .select()
        .eq('userid', userId)
        .single();
  }
  
  // Get team members
  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    try {
      final team =
          await client.from('teams').select().eq('teamid', teamId).single();
      final members = team['members'] as List;

      final userIds =
          members.map((member) => member['userid'].toString()).toList();

      if (userIds.isEmpty) {
        return [];
      }

      // Fetch each user individually to avoid potential RLS issues
      List<Map<String, dynamic>> allUsers = [];
      for (String userId in userIds) {
        try {
          final user = await client.from('users').select().eq('userid', userId).single();
          final member = members.firstWhere((m) => m['userid'] == userId);
          allUsers.add({...user, 'is_teacher': member['role'] == 'teacher'});
        } catch (e) {
          print('Error fetching user $userId: $e');
          // Continue with next user
        }
      }

      return allUsers;
    } catch (e) {
      print('Error getting team members: $e');
      return [];
    }
  }
  
  // Get sprint progress (for teachers)
  Future<Map<String, dynamic>> getSprintProgress(String teamId) async {
    try {
      final tasks = await getTeamTasks(teamId);

      int totalTasks = tasks.length;
      int completedTasks =
          tasks
              .where(
                (task) =>
                    task['status'] == 'done' || task['status'] == 'accepted',
              )
              .length;
      int inProgressTasks =
          tasks.where((task) => task['status'] == 'in_progress').length;
      int todoTasks = tasks.where((task) => task['status'] == 'todo').length;

      return {
        'total': totalTasks,
        'completed': completedTasks,
        'in_progress': inProgressTasks,
        'todo': todoTasks,
        'progress_percentage':
            totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
      };
    } catch (e) {
      print('Error getting sprint progress: $e');
      return {
        'total': 0,
        'completed': 0,
        'in_progress': 0,
        'todo': 0,
        'progress_percentage': 0,
      };
    }
  }
}