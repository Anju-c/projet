import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart'; // Added import statement for UserModel

class TeamProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  List<TeamModel> _teams = [];
  bool _isLoading = false;

  TeamProvider(this._supabaseService);

  List<TeamModel> get teams => _teams;
  bool get isLoading => _isLoading;

  Future<void> loadTeams(String userId,String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final teams = await _supabaseService.getUserTeams(userId,role);
      _teams = teams;
    } catch (e) {
      print('Error loading teams: $e');
      _teams = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTeam({
    required String teamname,
    required String teamcode,
    required String createdBy,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final createdTeam = await _supabaseService.createTeam(
        teamname: teamname,
        teamcode: teamcode,
        createdBy: createdBy,
        status: status,
      );
      _teams.add(createdTeam);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeam({
    required String teamid,
    String? teamname,
    String? teamcode,
    String? status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedTeam = await _supabaseService.updateTeam(
        teamid: teamid,
        teamname: teamname,
        teamcode: teamcode,
        status: status,
      );
      final index = _teams.indexWhere((t) => t.teamid == teamid);
      if (index != -1) {
        _teams[index] = updatedTeam;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamid) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.deleteTeam(teamid);
      _teams.removeWhere((team) => team.teamid == teamid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinTeam({
    required String teamid,
    required String userId,
    String role = 'member',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.joinTeam(
        teamid: teamid,
        userId: userId,
        role: role,
      );
      await loadTeams(userId,role);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveTeam({
    required String teamid,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.leaveTeam(
        teamid: teamid,
        userId: userId,
      );
      _teams.removeWhere((team) => team.teamid == teamid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<UserModel>> getTeamMembers(String teamid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final members = await _supabaseService.getTeamMembers(teamid);
      return members;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
