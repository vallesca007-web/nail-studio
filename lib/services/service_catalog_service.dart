import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/studio_service.dart';

class ServiceCatalogException implements Exception {
  const ServiceCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ServiceCatalogService {
  ServiceCatalogService._();

  static final ServiceCatalogService instance = ServiceCatalogService._();
  static const _timeout = Duration(seconds: 15);

  final http.Client _client = http.Client();

  Future<List<StudioService>> loadServices({required String category}) async {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/servicios').replace(
      queryParameters: {'categoria': category},
    );

    try {
      final response = await _client.get(uri).timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic> &&
                decoded['error'] is String
            ? decoded['error'] as String
            : 'No se pudieron cargar los servicios.';
        throw ServiceCatalogException(message);
      }
      if (decoded is! List) {
        throw const ServiceCatalogException(
          'El servidor devolvió un catálogo inválido.',
        );
      }

      return decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Datos de servicio inválidos.');
        }
        return StudioService.fromJson(item);
      }).toList();
    } on http.ClientException catch (error) {
      debugPrint('Error cargando servicios: ${error.message}');
      throw const ServiceCatalogException(
        'No pudimos conectar con el catálogo de servicios.',
      );
    } on TimeoutException {
      throw const ServiceCatalogException(
        'El servidor tardó demasiado. Intenta de nuevo.',
      );
    } on FormatException {
      throw const ServiceCatalogException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }
}
