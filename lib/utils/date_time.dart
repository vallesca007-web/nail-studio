/// Convierte la fecha y la hora que devuelve la API en un [DateTime] local.
///
/// La API responde `fecha` como `YYYY-MM-DD` y `hora` como `HH:MM`, pero se
/// aceptan también valores con hora o zona (`2026-11-24T00:00:00.000Z`,
/// `10:00:00`) porque un backend con otra conexión puede devolverlos así.
/// Se toman los primeros 10 y 5 caracteres y se arma la fecha sin zona horaria
/// para que la cita se muestre en el horario del estudio.
///
/// Devuelve `null` si el texto no es una fecha válida; la pantalla que lo usa
/// muestra un mensaje en lugar de fallar.
DateTime? parseStudioDateTime(String fecha, String hora) {
  final day = fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
  final time = hora.length >= 5 ? hora.substring(0, 5) : hora;
  try {
    return DateTime.parse('${day}T$time:00');
  } on FormatException {
    return null;
  }
}
