import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final http.Client _client = http.Client();

  Uri get _baseUri => Uri.parse(AppConfig.apiBaseUrl);

  Future<String> login({
    required String correo,
    required String contrasena,
  }) async {
    final response = await _client.post(
      _baseUri.resolve('auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'correo': correo.trim(), 'contrasena': contrasena}),
    );
    final body = _decode(response);
    if (body['token'] is! String) {
      throw const AuthException('El servidor no devolvió la sesión.');
    }
    return body['token'] as String;
  }

  Future<void> register({
    required String correo,
    required String contrasena,
  }) async {
    final response = await _client.post(
      _baseUri.resolve('auth/register'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'correo': correo.trim(), 'contrasena': contrasena}),
    );
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Respuesta inválida del servidor.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        decoded['error'] is String
            ? decoded['error'] as String
            : 'No se pudo completar la operación.',
      );
    }
    return decoded;
  }
}
