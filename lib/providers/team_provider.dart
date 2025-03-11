import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class TeamProvider extends ChangeNotifier {
  List<TeamModel> _teams = [];
  TeamModel? _selectedTeam;
  bool _isLoading = false;
  String? _error;
  List<UserModel> _teamMembers = [];

  List<TeamModel> get teams => _teams;
  TeamModel? get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserModel> get teamMembers => _teamMembers;

  final SupabaseService _supabaseService = SupabaseService();

  Future<void> loadUserTeams(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final teamsData = await _supabaseService.getUserTeams(userId);
      _teams = teamsData.map((team) => TeamModel.fromJson(team)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
        );

        _teams[index] = updatedTeam;

        if (_selectedTeam?.id == teamId) {
          _selectedTeam = updatedTeam;
        }
      }
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
      return {
        'total': 0,
        'completed': 0,
        'in_progress': 0,
        'todo': 0,
        'progress_percentage': 0,
      };
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
