import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../models/session_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authApi);

  final AuthApi _authApi;

  SessionUser? _user;
  bool _loading = true;

  SessionUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _loading;

  Future<void> loadSession() async {
    _loading = true;
    notifyListeners();

    try {
      final res = await _authApi.me();
      final userMap = res['user'] as Map<String, dynamic>?;

      if (userMap != null) {
        _user = SessionUser(
          id: userMap['id'].toString(),
          email: userMap['email'].toString(),
          role: userMap['role'].toString(),
        );
      } else {
        _user = null;
      }
    } catch (_) {
      _user = null;
    }

    _loading = false;
    notifyListeners();
  }

  void setUser(SessionUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {}

    _user = null;
    notifyListeners();
  }
}