import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._supabaseService);

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  /// ✅ Loads the current user safely even before login
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      print("⚠️ loadCurrentUser(): No user is logged in.");
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final fetchedUser = await _supabaseService.getCurrentUser();
      _currentUser = fetchedUser;
    } catch (e) {
      _error = e.toString();
      print("❌ loadCurrentUser() error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;

    try {
      _users = await _supabaseService.getUsers();
    } catch (e) {
      _error = e.toString();
      print("❌ loadUsers() error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;

    try {
      await _supabaseService.signIn(email: email, password: password);

      // Wait a tick to ensure session is saved before fetching user
      await Future.delayed(Duration(milliseconds: 100));

      await loadCurrentUser();

      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      print("❌ signIn() error: $_error");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      await Future.delayed(Duration(milliseconds: 100));
      await loadCurrentUser();

      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      print("❌ signUp() error: $_error");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;

    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
      print("❌ signOut() error: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String role,
  }) async {
    if (_currentUser == null) {
      _error = "User not logged in.";
      return false;
    }

    _isLoading = true;
    _error = null;

    try {
      _currentUser = await _supabaseService.updateProfile(
        userId: _currentUser!.id,
        name: name,
        role: role,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      print("❌ updateProfile() error: $_error");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
