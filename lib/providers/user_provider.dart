import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isTeacher => _user?.isTeacher ?? false;

  final SupabaseService _supabaseService = SupabaseService();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required bool isTeacher,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        name: name,
        email: email,
        password: password,
        isTeacher: isTeacher,
      );

      if (response.user != null) {
        final userData = await _supabaseService.getUserProfile(
          response.user!.id,
        );
        _user = UserModel.fromJson(userData);
      } else {
        _error = 'Failed to create user';
      }
    } catch (e) {
      _error = e.toString();
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
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          final userData = await _supabaseService.getUserProfile(
            response.user!.id,
          );
          _user = UserModel.fromJson(userData);
        } catch (e) {
          // If profile doesn't exist, create it
          if (e.toString().contains('contains 0 rows')) {
            await _supabaseService.createUserProfile(
              userId: response.user!.id,
              email: email,
              name: email.split('@')[0], // Temporary name from email
              isTeacher: false, // Default to student
            );
            // Try getting the profile again
            final userData = await _supabaseService.getUserProfile(
              response.user!.id,
            );
            _user = UserModel.fromJson(userData);
          } else {
            rethrow;
          }
        }
      } else {
        _error = 'Invalid credentials';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
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
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser != null) {
        final userData = await _supabaseService.getUserProfile(currentUser.id);
        _user = UserModel.fromJson(userData);
      }
    } catch (e) {
      _error = e.toString();
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
