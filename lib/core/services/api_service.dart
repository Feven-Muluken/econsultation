import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../storage/secure_storage.dart';

class ApiServiceException implements Exception {
  ApiServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

  String get _baseUrl {
    final fromEnv = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (fromEnv.startsWith('http')) {
      return fromEnv;
    }
    return 'https://backend.e-consultation.gov.et';
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final identifier = email.trim();

    final payload = await _requestWithFallback(
      method: 'POST',
      paths: const [
        '/api/v1/login',
      ],
      body: {
        'email': identifier,
        'password': password,
      },
      flow: _AuthFlow.login,
    );
    print('Login response payload: $payload');

    if (_isBusinessFailure(payload)) {
      final rawMessage = _extractErrorMessage(payload);
      throw ApiServiceException(
        _mapAuthMessage(
          flow: _AuthFlow.login,
          message: rawMessage,
          payload: payload,
        ),
      );
    }
    final token = _extractToken(payload);
    if (token == null || token.trim().isEmpty) {
      final rawMessage = _extractErrorMessage(payload);
      throw ApiServiceException(
        _mapAuthMessage(
          flow: _AuthFlow.login,
          message: rawMessage,
          payload: payload,
        ),
      );
    }

    return token;
  }
  Future<String> logintoGetID({
    required String email,
    required String password,
  }) async {
    final identifier = email.trim();

    final payload = await _requestWithFallback(
      method: 'POST',
      paths: const [
        '/api/v1/login',
      ],
      body: {
        'email': identifier,
        'password': password,
      },
      flow: _AuthFlow.login,
    );
    print('Login response payload: $payload');

    if (_isBusinessFailure(payload)) {
      final rawMessage = _extractErrorMessage(payload);
      throw ApiServiceException(
        _mapAuthMessage(
          flow: _AuthFlow.login,
          message: rawMessage,
          payload: payload,
        ),
      );
    }
    final id = extractuserId(payload);
    if (id == null || id.trim().isEmpty) {
      final rawMessage = _extractErrorMessage(payload);
      throw ApiServiceException(
        _mapAuthMessage(
          flow: _AuthFlow.login,
          message: rawMessage,
          payload: payload,
        ),
      );
    }

    return id;
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? middleName,
    String? confirmPassword,
    String? phone,
  }) async {
    final resolvedMiddleName = (middleName == null || middleName.trim().isEmpty)
        ? lastName.trim()
        : middleName.trim();
    final resolvedConfirmPassword =
        (confirmPassword == null || confirmPassword.isEmpty)
            ? password
            : confirmPassword;
    await _requestWithFallback(
      method: 'POST',
      paths: const [
        '/api/v1/signup',
      ],
      body: {
        'first_name': firstName.trim(),
        'middle_name': resolvedMiddleName,
        'last_name': lastName.trim(),
        'full_name': [firstName.trim(), resolvedMiddleName, lastName.trim()]
            .where((part) => part.isNotEmpty)
            .join(' '),
        'email': email.trim(),
        'password': password,
        'confirm_password': resolvedConfirmPassword,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      flow: _AuthFlow.register,
    );
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await _requestWithFallback(
      method: 'POST',
      paths: const [
        '/api/v1/forgot-password',
      ],
      body: {
        'email': email.trim(),
      },
      flow: _AuthFlow.forgotPassword,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    String? confirmPassword,
  }) async {
    final resolvedConfirmPassword =
        (confirmPassword == null || confirmPassword.trim().isEmpty)
            ? newPassword
            : confirmPassword.trim();

    await _requestWithFallback(
      method: 'POST',
      paths: const [
        '/api/v1/reset-password',
      ],
      body: {
        'email': email.trim(),
        'password': newPassword,
        'confirm_password': resolvedConfirmPassword,
        'token': code.trim(),
      },
      flow: _AuthFlow.resetPassword,
    );
  }

  Future<Map<String, dynamic>> fetchPortfolio(String? userid) async {
    final payload = await _requestWithFallback(
      method: 'GET',
      paths:  [
        '/api/v1/users/$userid',
      ],
      includeAuth: true,
    );
    print('Fetch portfolio response payload: $payload');

    return _extractMap(payload);
  }

  Future<Map<String, dynamic>> updatePortfolio({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? imagePath,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName.trim(),
      'middle_name': lastName.trim(),
      // 'last_name': lastName.trim(),
      'name': [firstName.trim(), lastName.trim()]
          .where((part) => part.isNotEmpty)
          .join(' '),
      'fullName': [firstName.trim(), lastName.trim()]
          .where((part) => part.isNotEmpty)
          .join(' '),
      'email': email.trim(),
      // 'phone': phone.trim(),
      'mobile_number': phone.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      if (imagePath != null && imagePath.trim().isNotEmpty)
        'imagePath': imagePath.trim(),
    };

    final userId = await SecureStorage.readUserId();    
    final paths = [
      '/api/v1/users/$userId',
    ];

    ApiServiceException? lastError;
    for (final method in const ['PUT', 'PATCH', 'POST']) {
      try {
        final payload = await _requestWithFallback(
          method: method,
          paths: paths,
          includeAuth: true,
          body: body,
        );
        return _extractMap(payload);
      } on ApiServiceException catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? ApiServiceException('Unable to update profile on server.');
  }

  Future<dynamic> _requestWithFallback({
    required String method,
    required List<String> paths,
    bool includeAuth = false,
    Map<String, dynamic>? body,
    _AuthFlow? flow,
  }) async {
    ApiServiceException? lastError;
    final headers = await _buildHeaders(includeAuth: includeAuth);

    for (final path in paths) {
      final uri = Uri.parse('$_baseUrl$path');
      try {
        final response = await _send(
          method: method,
          uri: uri,
          headers: headers,
          body: body,
        );

        final decoded = _tryDecodeJson(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (_isBusinessFailure(decoded)) {
            final message = _mapAuthMessage(
              flow: flow,
              message: _extractErrorMessage(decoded),
              statusCode: response.statusCode,
              payload: decoded,
            );
            throw ApiServiceException(message, statusCode: response.statusCode);
          }
          return decoded;
        }

        final message = _mapAuthMessage(
          flow: flow,
          message: _extractErrorMessage(decoded),
          statusCode: response.statusCode,
          payload: decoded,
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw ApiServiceException(message, statusCode: response.statusCode);
        }

        lastError = ApiServiceException(message, statusCode: response.statusCode);
      } catch (error) {
        if (error is ApiServiceException) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            rethrow;
          }
          lastError = error;
        } else if (error is SocketException) {
          lastError = ApiServiceException(
            'Network error: unable to reach server at $_baseUrl.',
          );
        } else if (error is HandshakeException) {
          lastError = ApiServiceException(
            'SSL/TLS handshake failed while connecting to server.',
          );
        } else if (error is TimeoutException) {
          lastError = ApiServiceException(
            'Request timeout: server took too long to respond.',
          );
        } else if (error is http.ClientException) {
          final normalized = error.message.toLowerCase();
          final message = normalized.contains('xmlhttprequest') ||
              normalized.contains('failed to fetch')
            ? 'Network request blocked in browser (possible CORS issue or unreachable backend from this origin).'
            : 'Network client error: ${error.message}';
          lastError = ApiServiceException(message);
        } else {
          lastError = ApiServiceException('Network request failed: $error');
        }
      }
    }

    throw lastError ?? ApiServiceException('Unable to connect to the server.');
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      case 'POST':
        return _client
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      case 'PUT':
        return _client
            .put(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      case 'PATCH':
        return _client
            .patch(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      default:
        throw ApiServiceException('Unsupported HTTP method: $method');
    }
  }

  Future<Map<String, String>> _buildHeaders({
    required bool includeAuth,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final apiKey = (dotenv.env['API_KEY'] ?? '').trim();
    if (apiKey.isNotEmpty && apiKey != '####') {
      headers['x-api-key'] = apiKey;
    }

    if (!includeAuth) {
      return headers;
    }

    final token = await SecureStorage.readToken();
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  dynamic _tryDecodeJson(String raw) {
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return <String, dynamic>{'message': raw};
    }
  }
  String? extractuserId(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    String? normalizeId(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
      return null;
    }

    final directUser = payload['user'];
    if (directUser is Map<String, dynamic>) {
      final userId = normalizeId(directUser['id']);
      if (userId != null) {
        return userId;
      }
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final dataId = normalizeId(data['id']);
      if (dataId != null) {
        return dataId;
      }

      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        final nestedUserId = normalizeId(nestedUser['id']);
        if (nestedUserId != null) {
          return nestedUserId;
        }
      }
    }

    final directId = normalizeId(payload['id']);
    if (directId != null) {
      return directId;
    }

    return null;
  }
  String? _extractToken(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final direct = payload['token'] ?? payload['access_token'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['token'] ?? data['access_token'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  String? _extractErrorMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'] ?? payload['error'] ?? payload['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errors = payload['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first;
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        final nestedMessage =
            data['message'] ?? data['error'] ?? data['detail'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    return null;
  }

  bool _isBusinessFailure(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return false;
    }

    final success = payload['success'];
    if (success is bool) {
      return success == false;
    }
    if (success is num) {
      return success == 0;
    }
    if (success is String) {
      final normalized = success.toLowerCase().trim();
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return true;
      }
    }

    final status = payload['status'];
    if (status is bool) {
      return status == false;
    }
    if (status is num) {
      return status == 0;
    }

    return false;
  }

  String _mapAuthMessage({
    required _AuthFlow? flow,
    required String? message,
    int? statusCode,
    dynamic payload,
  }) {
    final raw = (message ?? '').trim();
    final normalized = raw.toLowerCase();
    final payloadNormalized = payload
        .toString()
        .toLowerCase();
    final combined = '$normalized $payloadNormalized';
    print(  'Mapping auth message for flow $flow with raw="$raw", statusCode=$statusCode, payload=$payload');
    bool containsAny(List<String> patterns) {
      return patterns.any(combined.contains);
    }

    if (flow == _AuthFlow.login) {
      if (containsAny(const [
        'not activated',
        'not active',
        'unverified',
        'verify',
        'confirm email',
        'email confirmation',
      ])) {
        return 'Your account is not verified yet. Please confirm your email before signing in.';
      }
      if (containsAny(const [
            'user not found',
            'account not found',
            'email not found',
            'phone not found',
            'no user found',
            'no account',
            'does not exist',
            'not registered',
          ]) ||
          statusCode == 404) {
        return 'This email/phone is not registered. Please check it or create a new account.';
      }

      final passwordWrong = containsAny(const [
        'wrong password',
        'incorrect password',
        'password is incorrect',
        'invalid password',
      ]);

      if (passwordWrong) {
        return 'Incorrect password. Please try again.';
      }
      final passwordError = containsAny(const [
        'invalid password',
        'password is invalid'
      ]);

      if (passwordError) {
        return 'Password does not meet requirements. Please check it is 8 characters.';
      }

      final identifierInvalid = containsAny(const [
        'invalid email',
        'email is invalid',
        'invalid phone',
        'phone is invalid',
        'invalid username',
      ]);

      if (identifierInvalid) {
        return 'Please enter a valid email or phone number.';
      }

      if (containsAny(const [
            'invalid credential',
            'invalid credentials',
            'incorrect',
            'unauthorized',
            'authentication failed',
            'bad credentials',
          ]) ||
          statusCode == 401 ||
          statusCode == 403) {
        return 'Incorrect login credentials. Please check your email/phone and password.';
      }

      if (statusCode == 422) {
        if (containsAny(const ['email', 'user', 'account'])) {
          return 'This email/phone is not registered. Please check it or create a new account.';
        }
        if (containsAny(const ['password'])) {
          return 'Incorrect password. Please try again.';
        }
      }

      if (raw.isNotEmpty) {
        return raw;
      }
      return 'Unable to sign in right now. Please try again.';
    }

    if (flow == _AuthFlow.register) {
      if (normalized.contains('already') ||
          normalized.contains('taken') ||
          normalized.contains('exists') ||
          normalized.contains('duplicate') ||
          normalized.contains('unique')) {
        return 'An account with this email already exists.';
      }
      if (normalized.contains('confirm') && normalized.contains('password')) {
        return 'Password confirmation does not match.';
      }
      if (normalized.contains('verify') ||
          normalized.contains('activation') ||
          normalized.contains('check your email')) {
        return 'Registration successful. Please check your email to verify your account.';
      }
      if (statusCode == 422) {
        return raw.isNotEmpty
            ? raw
            : 'Some registration fields are invalid. Please review and try again.';
      }
      if (raw.isNotEmpty) {
        return raw;
      }
      return 'Unable to register at the moment. Please try again.';
    }

    if (flow == _AuthFlow.forgotPassword) {
      if (containsAny(const [
        'user not found',
        'account not found',
        'email not found',
        'no user',
        'not registered',
      ]) || statusCode == 404) {
        return 'No account found for this email address.';
      }
      if (containsAny(const [
            'invalid email',
            'email is invalid',
            'must be a valid email',
          ]) ||
          statusCode == 422) {
        return raw.isNotEmpty
            ? raw
            : 'Please enter a valid email address.';
      }
      if (containsAny(const [
        'too many',
        'rate limit',
        'throttle',
      ])) {
        return 'Too many attempts. Please wait and try again.';
      }
      if (raw.isNotEmpty) {
        return raw;
      }
      return 'Unable to send reset code right now. Please try again.';
    }

    if (flow == _AuthFlow.resetPassword) {
      if (containsAny(const [
            'invalid code',
            'code is invalid',
            'invalid otp',
            'wrong code',
            'incorrect code',
          ]) ||
          statusCode == 401) {
        return 'Invalid verification code. Please check and try again.';
      }
      if (containsAny(const [
        'expired',
        'code expired',
        'otp expired',
      ])) {
        return 'Verification code expired. Please request a new code.';
      }
      if (containsAny(const [
        'confirm',
        'password confirmation',
        'passwords do not match',
      ])) {
        return 'Password confirmation does not match.';
      }
      if (containsAny(const [
            'password',
            'too short',
            'at least',
            'requirements',
          ]) &&
          statusCode == 422) {
        return raw.isNotEmpty
            ? raw
            : 'Password does not meet the required format.';
      }
      if (containsAny(const [
            'user not found',
            'email not found',
            'account not found',
          ]) ||
          statusCode == 404) {
        return 'No account found for this email address.';
      }
      if (raw.isNotEmpty) {
        return raw;
      }
      return 'Unable to reset password right now. Please try again.';
    }

    if (raw.isNotEmpty) {
      return raw;
    }
    return statusCode == null
        ? 'Request failed. Please try again.'
        : 'Request failed with status $statusCode.';
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return payload;
    }

    throw ApiServiceException('Unexpected response format from server.');
  }
}

enum _AuthFlow { login, register, forgotPassword, resetPassword }


// token for jo 'Sv45GCMIOEeG6xw0cKnLaUwx6K7Rbi7UIqY9ViTB'
// email:  yohannestaye8780@gmail.com
