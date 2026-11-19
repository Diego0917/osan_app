import 'package:flutter_test/flutter_test.dart';
import 'package:osan_app/models/entrega.dart';

void main() {
  test('Calcula correctamente el total del día, rango semanal y rango mensual', () {
    final entrega = Entrega(
      clienteId: 1,
      cantidadBotellas: 12,
      precioUnitario: 2500,
      fecha: '2026-11-19',
    );

    expect(entrega.total, 30000.0);
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
}
