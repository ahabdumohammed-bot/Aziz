import '../models/user_model.dart';

/// Local-only auth service.
/// Credentials: admin@gmail.com / admin123
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  static const _adminEmail = 'admin@gmail.com';
  static const _adminPassword = 'admin123';

  /// Login — only admin@gmail.com / admin123 is accepted.
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate network
    if (email.trim().toLowerCase() == _adminEmail &&
        password.trim() == _adminPassword) {
      _currentUser = UserModel(
        userId: 'admin-001',
        email: _adminEmail,
        fullName: 'Admin User',
        age: 0,
        condition: '',
        createdAt: DateTime(2024, 1, 1),
      );
      return _currentUser;
    }
    throw Exception('Invalid email or password.');
  }

  /// Register — creates a local user session (no persistence).
  Future<UserModel?> register(
    String email,
    String password,
    String fullName, {
    int age = 0,
    String condition = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserModel(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      age: age,
      condition: condition,
      createdAt: DateTime.now(),
    );
    return _currentUser;
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = null;
  }

  /// No persistent session — always null on cold start.
  Future<UserModel?> loadCurrentUser() async => _currentUser;
}
