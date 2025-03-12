import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class TeamProvider extends ChangeNotifier {
  List<TeamModel> _teams = [];
  List<TeamModel> _allTeams = [];
  TeamModel? _selectedTeam;
  bool _isLoading = false;
  String? _error;
  List<UserModel> _teamMembers = [];

  List<TeamModel> get teams => _teams;
  List<TeamModel> get allTeams => _allTeams;
  TeamModel? get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserModel> get teamMembers => _teamMembers;

  final SupabaseService _supabaseService = SupabaseService();
  final Logger _logger = Logger();

  Future<void> loadUserTeams(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Loading teams for userId: $userId');
      final teamsData = await _supabaseService.getUserTeams(userId);
      _logger.i('Raw teams data from Supabase: $teamsData');

      if (teamsData.isEmpty) {
        _logger.i('No teams found for user $userId');
        _teams = [];
      } else {
        _teams = [];
        for (var teamData in teamsData) {
          try {
            final team = TeamModel.fromJson(teamData);
            _teams.add(team);
            _logger.i('Successfully parsed team: ${team.name}, ID: ${team.id}');
          } catch (e) {
            _logger.e('Error parsing team data: $e');
            _logger.e('Problematic team data: $teamData');
          }
        }
        _logger.i('Total teams loaded for user: ${_teams.length}');
      }
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in loadUserTeams: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final teamsData = await _supabaseService.getAllTeams();
      _logger.i('Raw data from getAllTeams: $teamsData');

      if (teamsData.isEmpty) {
        _logger.i('No teams found in database!');
      } else {
        _logger.i('Teams found in database: ${teamsData.length}');
        for (var team in teamsData) {
          _logger.i(
            'Team: ${team['teamname']}, ID: ${team['teamid']}, Members: ${team['members']}',
          );
        }
      }

      _allTeams = teamsData.map((team) => TeamModel.fromJson(team)).toList();
      _logger.i('All teams loaded: ${_allTeams.length}');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in loadAllTeams: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeamsRaw() async {
    try {
      final rawTeams = await _supabaseService.client.from('teams').select('*');
      _logger.i('Direct query - All teams in DB: $rawTeams');
      return rawTeams;
    } catch (e) {
      _logger.e('Error in direct teams query: $e');
      return [];
    }
  }

  Future<void> createTeam({
    required String teamName,
    required String userId,
    required bool isTeacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Creating team for userId: $userId');
      final teamData = await _supabaseService.createTeam(
        teamName: teamName,
        userId: userId,
        isTeacher: isTeacher,
      );

      final newTeam = TeamModel.fromJson({
        ...teamData,
        'is_teacher': isTeacher,
      });

      _teams.add(newTeam);
      _selectedTeam = newTeam;
      await loadAllTeams();
      _logger.i('Team created: ${newTeam.name}, ID: ${newTeam.id}');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in createTeam: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinTeam({
    required String teamCode,
    required String userId,
    required bool isTeacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Joining team with code: $teamCode for userId: $userId');
      final teamData = await _supabaseService.joinTeam(
        teamCode: teamCode,
        userId: userId,
        isTeacher: isTeacher,
      );

      final newTeam = TeamModel.fromJson({
        ...teamData,
        'is_teacher': isTeacher,
      });

      _teams.add(newTeam);
      _selectedTeam = newTeam;
      await loadAllTeams();
      _logger.i('Team joined: ${newTeam.name}, ID: ${newTeam.id}');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in joinTeam: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeamName({
    required String teamId,
    required String newName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateTeamName(teamId: teamId, newName: newName);

      final index = _teams.indexWhere((team) => team.id == teamId);
      if (index != -1) {
        final updatedTeam = TeamModel(
          id: _teams[index].id,
          name: newName,
          code: _teams[index].code,
          createdBy: _teams[index].createdBy,
          members: _teams[index].members,
          isTeacher: _teams[index].isTeacher,
          status: _teams[index].status,
        );

        _teams[index] = updatedTeam;

        if (_selectedTeam?.id == teamId) {
          _selectedTeam = updatedTeam;
        }
      }
      await loadAllTeams();
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in updateTeamName: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveAbstract(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Approving abstract for teamId: $teamId');
      await _supabaseService.approveAbstract(teamId);
      final index = _teams.indexWhere((team) => team.id == teamId);
      if (index != -1) {
        final updatedTeam = TeamModel(
          id: _teams[index].id,
          name: _teams[index].name,
          code: _teams[index].code,
          createdBy: _teams[index].createdBy,
          members: _teams[index].members,
          isTeacher: _teams[index].isTeacher,
          status: 'accepted',
        );
        _teams[index] = updatedTeam;
        if (_selectedTeam?.id == teamId) {
          _selectedTeam = updatedTeam;
        }
      }
      await loadAllTeams();
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in approveAbstract: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTeam(String teamId) {
    final team = _teams.firstWhere(
      (team) => team.id == teamId,
      orElse: () => throw Exception('Team not found'),
    );
    _selectedTeam = team;
    loadTeamMembers(teamId);
    notifyListeners();
  }

  Future<void> loadTeamMembers(String teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final membersData = await _supabaseService.getTeamMembers(teamId);
      _teamMembers =
          membersData.map((member) => UserModel.fromJson(member)).toList();
      _logger.i('Loaded team members for team $teamId: ${_teamMembers.length}');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in loadTeamMembers: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getSprintProgress(String teamId) async {
    try {
      return await _supabaseService.getSprintProgress(teamId);
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in getSprintProgress: $_error');
      return {
        'total': 0,
        'completed': 0,
        'in_progress': 0,
        'todo': 0,
        'progress_percentage': 0,
      };
    }
  }

  Future<void> forceRefresh(String userId) async {
    _teams = [];
    _selectedTeam = null;
    notifyListeners();

    _logger.i('Force refreshing teams for user: $userId');
    await loadUserTeams(userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
