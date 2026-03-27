import 'package:flutter/material.dart';
import '../models/session_user.dart';

class AuthController extends ChangeNotifier {
  SessionUser? _user;
  bool _loading = false;

  SessionUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _loading;

  void setUser(SessionUser user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}