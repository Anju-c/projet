import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  final Logger _logger = Logger();

  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  // Initialize Supabase client
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url:
            'https://bjtijiyjqmfphyibkpma.supabase.co', // Replace with your Supabase URL
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdGlqaXlqcW1mcGh5aWJrcG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDU5NzAsImV4cCI6MjA1NjIyMTk3MH0.BrPFmPy39lkXQbFWjrMMbcc-AEabWTEgppaK1ddqU8k', // Replace with your Supabase Anon Key
        debug: true,
      );
      _logger.i('***** Supabase init completed *****');
      await checkTablesExist();
      await ensureUsersTable(); // Ensure the users table matches the schema
    } catch (e) {
      _logger.e('Error initializing Supabase: $e');
      if (e.toString().contains('infinite recursion')) {
        _logger.w(
          'RLS policy may be misconfigured. Consider disabling RLS or fixing the policy.',
        );
      }
      rethrow;
    }
  }

  SupabaseClient get client => _client;

  Future<void> checkTablesExist() async {
    try {
      _logger.i('Checking if tables exist...');
      final usersExist =
          await client.from('users').select().limit(1).maybeSingle();
      _logger.i('Users table exists: ${usersExist != null}');
      final teamsExist =
          await client.from('teams').select().limit(1).maybeSingle();
      _logger.i('Teams table exists: ${teamsExist != null}');
      final tasksExist =
          await client.from('tasks').select().limit(1).maybeSingle();
      _logger.i('Tasks table exists: ${tasksExist != null}');
      _logger.i('All tables exist and are accessible');
    } catch (e) {
      _logger.e('Error checking tables: $e');
      rethrow;
    }
  }

  // Ensure the users table exists with the correct schema
  Future<void> ensureUsersTable() async {
    try {
      // Supabase doesn't provide a direct way to list tables via the client,
      // so we assume the table exists if the previous query succeeded.
      // If the table schema doesn't match, we'll catch errors in getUserProfile.
      _logger.i('Ensuring users table schema...');
    } catch (e) {
      _logger.e('Error ensuring users table: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      _logger.i('Fetching user profile for userId: $userId');
      final response =
          await client
              .from('users')
              .select()
              .eq('userid', userId) // Changed from 'id' to 'userid'
              .single(); // Use .single() directly instead of .execute()
      if (response == null) {
        _logger.w('No profile found for userId: $userId, creating default...');
        await client.from('users').insert({
          'userid': userId, // Changed from 'id' to 'userid'
          'email':
              (await client.auth.getUser(userId)).user?.email ??
              'unknown@example.com',
          'name': 'Unknown User',
          'role': 'student',
          'accesscode': null,
        });
        return await client
            .from('users')
            .select()
            .eq('userid', userId) // Changed from 'id' to 'userid'
            .single();
      }
      _logger.i('User profile fetched: ${response['userid']}');
      return response;
    } catch (e) {
      _logger.e('Error fetching user profile for $userId: $e');
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isTeacher,
  }) async {
    try {
      _logger.i('Signing up user with email: $email');
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await client.from('users').insert({
          'userid': response.user!.id, // Changed from 'id' to 'userid'
          'email': email,
          'name': name,
          'role': isTeacher ? 'teacher' : 'student',
          'accesscode': null,
        });
        _logger.i('User signed up and profile created: ${response.user!.id}');
      } else {
        throw Exception('User signup failed: No user returned');
      }
    } catch (e) {
      _logger.e('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      _logger.i('Signing in user with email: $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Sign-in failed: No user returned');
      }
      _logger.i('User signed in: ${response.user!.id}');
    } catch (e) {
      _logger.e('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await client.auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error signing out: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserTeams(String userId) async {
    try {
      _logger.i('Fetching teams for userId: $userId');
      final teams =
          await client
              .from('teams')
              .select()
              .contains('members', '{"userid": "$userId"}')
              .maybeSingle(); // Use .maybeSingle() for safety

      if (teams == null) {
        _logger.i(
          'No teams found with contains filter. Trying manual filtering...',
        );
        final allTeams = await client.from('teams').select();
        _logger.i('All teams in DB: ${allTeams.length}');

        final userTeams =
            allTeams.where((team) {
              final members = team['members'] as List?;
              if (members == null) return false;
              return members.any(
                (member) => member is Map && member['userid'] == userId,
              );
            }).toList();

        _logger.i('Manually filtered teams: ${userTeams.length}');
        return userTeams.map<Map<String, dynamic>>((team) {
          final members = team['members'] as List;
          final userMember = members.firstWhere(
            (member) => member['userid'] == userId,
            orElse: () => {'role': 'student'},
          );
          return {...team, 'is_teacher': userMember['role'] == 'teacher'};
        }).toList();
      }

      final members = teams['members'] as List;
      _logger.i('Team ${teams['teamid']} has ${members.length} members');
      final userMember = members.firstWhere(
        (member) => member['userid'] == userId,
        orElse: () => {'role': 'student'},
      );
      return [
        {...teams, 'is_teacher': userMember['role'] == 'teacher'},
      ];
    } catch (e) {
      _logger.e('Error fetching teams for user $userId: $e');
      try {
        _logger.i('Attempting fallback manual filtering...');
        final allTeams = await client.from('teams').select();
        _logger.i('All teams in DB: ${allTeams.length}');

        final userTeams =
            allTeams.where((team) {
              final members = team['members'] as List?;
              if (members == null) return false;
              return members.any(
                (member) => member is Map && member['userid'] == userId,
              );
            }).toList();

        _logger.i('Manually filtered teams: ${userTeams.length}');
        return userTeams.map<Map<String, dynamic>>((team) {
          final members = team['members'] as List;
          final userMember = members.firstWhere(
            (member) => member['userid'] == userId,
            orElse: () => {'role': 'student'},
          );
          return {...team, 'is_teacher': userMember['role'] == 'teacher'};
        }).toList();
      } catch (fallbackError) {
        _logger.e('Fallback failed: $fallbackError');
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      final teams = await client.from('teams').select();
      _logger.i('Fetched all teams: ${teams.length}');
      return teams;
    } catch (e) {
      _logger.e('Error fetching all teams: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTeam({
    required String teamName,
    required String userId,
    required bool isTeacher,
  }) async {
    try {
      final teamCode = _generateTeamCode();
      final teamData = {
        'teamname': teamName,
        'teamcode': teamCode,
        'createdby': userId,
        'members': [
          {
            'userid': userId,
            'role': isTeacher ? 'teacher' : 'student',
            'joined_at': DateTime.now().toIso8601String(),
          },
        ],
        'status': 'pending',
      };
      final response =
          await client.from('teams').insert(teamData).select().single();
      _logger.i('Team created: ${response['teamname']}');
      return response;
    } catch (e) {
      _logger.e('Error creating team: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinTeam({
    required String teamCode,
    required String userId,
    required bool isTeacher,
  }) async {
    try {
      final team =
          await client.from('teams').select().eq('teamcode', teamCode).single();
      final members = (team['members'] as List?) ?? [];
      if (!members.any((m) => m['userid'] == userId)) {
        members.add({
          'userid': userId,
          'role': isTeacher ? 'teacher' : 'student',
          'joined_at': DateTime.now().toIso8601String(),
        });
        final updatedTeam =
            await client
                .from('teams')
                .update({'members': members})
                .eq('teamcode', teamCode)
                .select()
                .single();
        _logger.i('User $userId joined team: ${updatedTeam['teamname']}');
        return updatedTeam;
      }
      _logger.i('User $userId already in team: ${team['teamname']}');
      return team;
    } catch (e) {
      _logger.e('Error joining team: $e');
      rethrow;
    }
  }

  Future<void> updateTeamName({
    required String teamId,
    required String newName,
  }) async {
    try {
      await client
          .from('teams')
          .update({'teamname': newName})
          .eq('teamid', teamId);
      _logger.i('Team $teamId name updated to $newName');
    } catch (e) {
      _logger.e('Error updating team name: $e');
      rethrow;
    }
  }

  Future<void> approveAbstract(String teamId) async {
    try {
      await client
          .from('teams')
          .update({'status': 'accepted'})
          .eq('teamid', teamId);
      _logger.i('Abstract approved for team $teamId');
    } catch (e) {
      _logger.e('Error approving abstract: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    try {
      final team =
          await client
              .from('teams')
              .select('members')
              .eq('teamid', teamId)
              .single();
      final members = (team['members'] as List?) ?? [];
      _logger.i('Fetched ${members.length} members for team $teamId');
      return members.map((m) => m as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.e('Error fetching team members: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSprintProgress(String teamId) async {
    try {
      final tasks = await client.from('tasks').select().eq('teamid', teamId);
      final total = tasks.length;
      final completed = tasks.where((t) => t['status'] == 'completed').length;
      final inProgress =
          tasks.where((t) => t['status'] == 'in_progress').length;
      final todo = tasks.where((t) => t['status'] == 'todo').length;
      final progressPercentage = total > 0 ? (completed / total) * 100 : 0;
      _logger.i('Sprint progress for team $teamId: $progressPercentage%');
      return {
        'total': total,
        'completed': completed,
        'in_progress': inProgress,
        'todo': todo,
        'progress_percentage': progressPercentage,
      };
    } catch (e) {
      _logger.e('Error fetching sprint progress: $e');
      rethrow;
    }
  }

  String _generateTeamCode() {
    const length = 5;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(
          DateTime.now().microsecondsSinceEpoch % chars.length,
        ),
      ),
    );
  }
}
