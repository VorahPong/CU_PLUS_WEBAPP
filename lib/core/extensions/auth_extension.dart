import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/controller/auth_controller.dart';

extension AuthX on BuildContext {
  AuthController get auth => watch<AuthController>();
  AuthController get authRead => read<AuthController>();
}