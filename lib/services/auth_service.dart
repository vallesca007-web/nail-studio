import 'dart:async';
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
  static const _timeout = Duration(seconds: 15);

  final http.Client _client = http.Client();

  // Uri.resolve trataría "/api" como archivo y perdería el prefijo,
  // por eso se arma la ruta igual que en AppointmentService.
  Uri _endpoint(String path) {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/$path');
  }

  Future<String> login({
    required String correo,
    required String contrasena,
  }) async {
    final body = await _post(
      'auth/login',
      correo: correo,
      contrasena: contrasena,
    );
    if (body['token'] is! String) {
      throw const AuthException('El servidor no devolvió la sesión.');
    }
    return body['token'] as String;
  }

  Future<void> register({
    required String correo,
    required String contrasena,
  }) async {
    await _post('auth/register', correo: correo, contrasena: contrasena);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required String correo,
    required String contrasena,
  }) async {
    try {
      final response = await _client
          .post(
            _endpoint(path),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'correo': correo.trim(),
              'contrasena': contrasena,
            }),
          )
          .timeout(_timeout);
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
    } on http.ClientException {
      throw const AuthException('No pudimos conectar con el servidor.');
    } on TimeoutException {
      throw const AuthException('El servidor tardó demasiado en responder.');
    } on FormatException {
      throw const AuthException('El servidor devolvió una respuesta inválida.');
    }
  }
}
