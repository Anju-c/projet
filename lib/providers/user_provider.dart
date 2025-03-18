import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  UserModel? _currentUser;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  UserProvider(this._supabaseService);

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
 
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.getCurrentUser();
    } catch (e) {
      _error = 'Failed to load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> getUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _supabaseService.getUser(userId);
    } catch (e) {
      _error = 'Failed to get user: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _supabaseService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required String userId,
    String? name,
    bool? isTeacher,
  }) async {
    try {
      final updatedUser = await _supabaseService.updateUser(
        userId: userId,
        name: name,
        isTeacher: isTeacher,
      );
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
