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
  final double totalHoy;
  final int botellasSemana;
  final double totalSemana;
  final int botellasMes;
  final double totalMes;

  const ResumenClienteSemana({
    this.botellasHoy = 0,
    this.totalHoy = 0.0,
    this.botellasSemana = 0,
    this.totalSemana = 0.0,
    this.botellasMes = 0,
    this.totalMes = 0.0,
  });
}

class ReporteClienteMes {
  final int clienteId;
  final String nombreCliente;
  final String telefono;
  final int botellasMes;
  final double totalMes;

  const ReporteClienteMes({
    required this.clienteId,
    required this.nombreCliente,
    required this.telefono,
    required this.botellasMes,
    required this.totalMes,
  });
}

class FormatoUtils {
  /// Formatea un número entero con separador de miles (ej: 12500 -> "12,500")
  static String entero(int valor) {
    final negativo = valor < 0;
    final texto = valor.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(texto[i]);
    }
    return negativo ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Formatea un monto de dinero con separador de miles (ej: 125000.5 -> "$125,000.50")
  static String moneda(double valor) {
    if (valor.isNaN || valor.isInfinite) return '\$0.00';
    final negativo = valor < 0;
    final fijo = valor.abs().toStringAsFixed(2);
    final partes = fijo.split('.');
    final parteEntera = int.tryParse(partes[0]) ?? 0;
    final parteDecimal = partes.length > 1 ? partes[1] : '00';
    final enteroFormateado = entero(parteEntera);
    final resultado =
        parteDecimal == '00' ? enteroFormateado : '$enteroFormateado.$parteDecimal';
    return negativo ? '-\$$resultado' : '\$$resultado';
  }
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

  static const List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static DateTime obtenerLunes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day - (fecha.weekday - 1));
  }

  static DateTime obtenerDomingo(DateTime fecha) {
    final lunes = obtenerLunes(fecha);
    return DateTime(lunes.year, lunes.month, lunes.day + 6);
  }

  static DateTime obtenerInicioMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, 1);
  }

  static DateTime obtenerFinMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month + 1, 0);
  }

  static String formatearMesAnio(DateTime fecha) {
    final nombreMes = meses[(fecha.month - 1).clamp(0, 11)];
    return '$nombreMes ${fecha.year}';
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
