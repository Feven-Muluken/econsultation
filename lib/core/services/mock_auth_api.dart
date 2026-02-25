class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MockAuthApi {
  MockAuthApi._();

  static final MockAuthApi instance = MockAuthApi._();

  static final Map<String, String> _registeredUsers = {};
  String? _pendingOtpEmail;
  String _lastOtp = '123456';

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final normalized = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(normalized)) {
      throw AuthException('Email already registered');
    }
    _registeredUsers[normalized] = password;
    _pendingOtpEmail = normalized;
    _lastOtp = '123456';
  }

  Future<void> resendOtp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_pendingOtpEmail == null) {
      throw AuthException('No pending verification');
    }
    _lastOtp = '123456';
  }

  Future<void> verifyOtp({required String otp}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (_pendingOtpEmail == null) {
      throw AuthException('No pending verification');
    }
    if (otp != _lastOtp) {
      throw AuthException('Invalid OTP');
    }
    _pendingOtpEmail = null;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final normalized = email.trim().toLowerCase();
    final storedPassword = _registeredUsers[normalized];
    if (storedPassword == null || storedPassword != password) {
      throw AuthException('Invalid credentials');
    }
    return 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
  }
}
