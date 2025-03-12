import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isTeacher = false;
  String? _error;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isTeacher => _isTeacher;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  final SupabaseService supabaseService = SupabaseService();
  final Logger _logger = Logger();

  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        _logger.i('Authenticated user ID: ${user.id}');
        final userData = await supabaseService.getUserProfile(user.id);
        _user = UserModel.fromJson(userData);
        _logger.i('User profile loaded: ${_user!.id}');
        _isTeacher = _user!.role == 'teacher';
      } else {
        _logger.w('No authenticated user found');
        _user = null;
      }
    } catch (e) {
      _error = e.toString();
      _logger.e('Error loading user: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isTeacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        isTeacher: isTeacher,
      );
      await loadUser();
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in signUp: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await supabaseService.signIn(email: email, password: password);
      await loadUser();
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in signIn: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await supabaseService.signOut();
      _user = null;
      _isTeacher = false;
    } catch (e) {
      _error = e.toString();
      _logger.e('Error in signOut: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
