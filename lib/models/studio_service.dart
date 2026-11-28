class StudioService {
  const StudioService({
    required this.id,
    required this.name,
    required this.category,
    required this.group,
    required this.cost,
    required this.durationMinutes,
    this.description,
    this.order = 0,
  });

  final int id;
  final String name;
  final String category;
  final String group;
  final String? description;
  final double cost;
  final int durationMinutes;
  final int order;

  factory StudioService.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final cost = json['costo'];
    final duration = json['duracion_min'];
    if (id is! int || cost is! num || duration is! int) {
      throw const FormatException('Datos de servicio inválidos.');
    }

    return StudioService(
      id: id,
      name: _stringValue(json['nombre']),
      category: _stringValue(json['categoria']),
      group: _stringValue(json['grupo']),
      description: json['descripcion'] is String
          ? json['descripcion'] as String
          : null,
      cost: cost.toDouble(),
      durationMinutes: duration,
      order: json['orden'] is int ? json['orden'] as int : 0,
    );
  }
}

String _stringValue(Object? value) => value is String ? value : '';
