class Entrega {
  final int? id;
  final int clienteId;
  final int cantidadBotellas;
  final double precioUnitario;
  final double total;
  final String fecha; // Formato YYYY-MM-DD

  Entrega({
    this.id,
    required this.clienteId,
    required this.cantidadBotellas,
    required this.precioUnitario,
    double? total,
    required this.fecha,
  }) : total = total ?? (cantidadBotellas * precioUnitario);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'cantidad_botellas': cantidadBotellas,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha': fecha,
    };
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      cantidadBotellas: map['cantidad_botellas'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      fecha: map['fecha'] as String,
    );
  }
}

class ResumenClienteSemana {
  final int botellasHoy;
  final int botellasSemana;
  final double totalSemana;

  const ResumenClienteSemana({
    this.botellasHoy = 0,
    this.botellasSemana = 0,
    this.totalSemana = 0.0,
  });
}

class FechaSemanaUtils {
  static const List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static DateTime obtenerLunes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day - (fecha.weekday - 1));
  }

  static DateTime obtenerDomingo(DateTime fecha) {
    final lunes = obtenerLunes(fecha);
    return DateTime(lunes.year, lunes.month, lunes.day + 6);
  }

  static String aIso(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime desdeIso(String iso) {
    final partes = iso.split('-');
    if (partes.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(partes[0]) ?? DateTime.now().year,
      int.tryParse(partes[1]) ?? 1,
      int.tryParse(partes[2]) ?? 1,
    );
  }

  static String formatearCorto(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  static String formatearConDia(String iso) {
    final fecha = desdeIso(iso);
    final nombreDia = diasSemana[fecha.weekday - 1];
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$nombreDia $d/$m/${fecha.year}';
  }
}
