class SessionUser {
  final String id;
  final String email;
  final String role;

  const SessionUser({
    required this.id,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';
}