import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/promotion.dart';

class PromotionServiceException implements Exception {
  const PromotionServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PromotionService {
  PromotionService._();

  static final PromotionService instance = PromotionService._();
  static const _timeout = Duration(seconds: 15);

  final http.Client _client = http.Client();

  Future<List<Promotion>> loadPromotions() async {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/promociones');
    try {
      final response = await _client.get(uri).timeout(_timeout);
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic> &&
                decoded['error'] is String
            ? decoded['error'] as String
            : 'No se pudieron cargar las promociones.';
        throw PromotionServiceException(message);
      }
      if (decoded is! List) {
        throw const PromotionServiceException(
          'El servidor devolvió una lista de promociones inválida.',
        );
      }

      return decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Datos de promoción inválidos.');
        }
        return Promotion.fromJson(item);
      }).toList();
    } on http.ClientException catch (error) {
      debugPrint('Error cargando promociones: ${error.message}');
      throw const PromotionServiceException(
        'No pudimos conectar con las promociones.',
      );
    } on TimeoutException {
      throw const PromotionServiceException(
        'El servidor tardó demasiado. Intenta de nuevo.',
      );
    } on FormatException {
      throw const PromotionServiceException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }
}
