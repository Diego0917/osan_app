import 'package:flutter_test/flutter_test.dart';
import 'package:osan_app/databases/database_helper.dart';
import 'package:osan_app/models/entrega.dart';

void main() {
  test('Calcula correctamente el total del día, rango semanal y rango mensual', () {
    final entrega = Entrega(
      clienteId: 1,
      cantidadBotellas: 12,
      precioUnitario: 2500,
      fecha: '2026-11-19',
      tipo: TipoEntrega.vendido,
    );

    expect(entrega.total, 30000.0);
    expect(entrega.tipo, TipoEntrega.vendido);
    expect(FormatoUtils.moneda(entrega.total), '\$30,000');

    final fecha = FechaSemanaUtils.desdeIso('2026-11-19');
    final lunes = FechaSemanaUtils.obtenerLunes(fecha);
    final domingo = FechaSemanaUtils.obtenerDomingo(fecha);
    final inicioMes = FechaSemanaUtils.obtenerInicioMes(fecha);
    final finMes = FechaSemanaUtils.obtenerFinMes(fecha);

    expect(FechaSemanaUtils.aIso(lunes), '2026-11-16');
    expect(FechaSemanaUtils.aIso(domingo), '2026-11-22');
    expect(FechaSemanaUtils.aIso(inicioMes), '2026-11-01');
    expect(FechaSemanaUtils.aIso(finMes), '2026-11-30');
    expect(FechaSemanaUtils.formatearMesAnio(fecha), 'Noviembre 2026');
  });

  test('Separa correctamente entregas de tipo dejado y vendido con compatibilidad', () {
    final dejado = Entrega(
      clienteId: 2,
      cantidadBotellas: 15,
      precioUnitario: 3000,
      fecha: '2026-11-22',
      tipo: TipoEntrega.dejado,
    );

    expect(dejado.precioUnitario, 0.0);
    expect(dejado.total, 0.0);
    expect(dejado.toMap()['tipo'], 'dejado');

    final dejadoDesdeMapa = Entrega.fromMap(dejado.toMap());
    expect(dejadoDesdeMapa.tipo, TipoEntrega.dejado);
    expect(dejadoDesdeMapa.total, 0.0);

    // Registros previos a la migración (sin columna tipo) se leen como vendido
    final legado = Entrega.fromMap({
      'id': 1,
      'cliente_id': 2,
      'cantidad_botellas': 10,
      'precio_unitario': 2000,
      'total': 20000,
      'fecha': '2026-11-20',
    });
    expect(legado.tipo, TipoEntrega.vendido);
    expect(legado.total, 20000.0);
  });

  test('Protege los 5 productos fijos del inventario y el histórico permanente', () {
    expect(DatabaseHelper.esProductoFijo('Botellas'), isTrue);
    expect(DatabaseHelper.esProductoFijo('jugos'), isTrue);
    expect(DatabaseHelper.esProductoFijo('DEVOLUCIONES'), isTrue);
    expect(DatabaseHelper.esProductoFijo('Botellas vendidas'), isTrue);
    expect(DatabaseHelper.esProductoFijo('Jugos salidos'), isTrue);
    expect(DatabaseHelper.esProductoFijo('Bolsas'), isFalse);

    expect(DatabaseHelper.esProductoHistorico('Jugos salidos'), isTrue);
    expect(DatabaseHelper.esProductoHistorico('Jugos'), isFalse);
  });
}
