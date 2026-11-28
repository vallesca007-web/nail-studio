class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.badge,
    required this.description,
    required this.endDate,
  });

  final int id;
  final String title;
  final String badge;
  final String description;
  final DateTime? endDate;

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Datos de promoción inválidos.');
    }

    final rawEndDate = json['fecha_fin'];
    final endDate = rawEndDate is String && rawEndDate.isNotEmpty
        ? DateTime.tryParse(rawEndDate)
        : null;

    return Promotion(
      id: id,
      title: _stringValue(json['titulo']),
      badge: _stringValue(json['etiqueta']),
      description: _stringValue(json['descripcion']),
      endDate: endDate,
    );
  }
}

String _stringValue(Object? value) => value is String ? value : '';
