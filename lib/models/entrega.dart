enum TipoEntrega {
  dejado,
  vendido;

  String get valorDb => this == TipoEntrega.dejado ? 'dejado' : 'vendido';

  static TipoEntrega fromDb(String? valor) {
    if (valor == 'dejado') return TipoEntrega.dejado;
    return TipoEntrega.vendido;
  }
}

class Entrega {
  final int? id;
  final int clienteId;
  final int cantidadBotellas;
  final double precioUnitario;
  final double total;
  final String fecha; // Formato YYYY-MM-DD
  final TipoEntrega tipo;

  Entrega({
    this.id,
    required this.clienteId,
    required this.cantidadBotellas,
    double precioUnitario = 0.0,
    double? total,
    required this.fecha,
    this.tipo = TipoEntrega.vendido,
  }) : precioUnitario = tipo == TipoEntrega.dejado ? 0.0 : precioUnitario,
       total = tipo == TipoEntrega.dejado
           ? 0.0
           : (total ?? (cantidadBotellas * precioUnitario));

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'cantidad_botellas': cantidadBotellas,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha': fecha,
      'tipo': tipo.valorDb,
    };
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    final tipo = TipoEntrega.fromDb(map['tipo'] as String?);
    return Entrega(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      cantidadBotellas: (map['cantidad_botellas'] as num).toInt(),
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      fecha: map['fecha'] as String,
      tipo: tipo,
    );
  }
}

class ResumenClienteSemana {
  final int botellasDejadasHoy;
  final int botellasDejadasSemana;
  final int botellasDejadasMes;
  final int botellasVendidasHoy;
  final double totalHoy;
  final int botellasVendidasSemana;
  final double totalSemana;
  final int botellasVendidasMes;
  final double totalMes;

  const ResumenClienteSemana({
    this.botellasDejadasHoy = 0,
    this.botellasDejadasSemana = 0,
    this.botellasDejadasMes = 0,
    this.botellasVendidasHoy = 0,
    this.totalHoy = 0.0,
    this.botellasVendidasSemana = 0,
    this.totalSemana = 0.0,
    this.botellasVendidasMes = 0,
    this.totalMes = 0.0,
  });
}

class ReporteClienteMes {
  final int clienteId;
  final String nombreCliente;
  final String telefono;
  final int botellasDejadasMes;
  final int botellasVendidasMes;
  final double totalMes;

  const ReporteClienteMes({
    required this.clienteId,
    required this.nombreCliente,
    required this.telefono,
    this.botellasDejadasMes = 0,
    required this.botellasVendidasMes,
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
