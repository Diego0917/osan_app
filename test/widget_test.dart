import 'package:flutter_test/flutter_test.dart';
import 'package:osan_app/models/entrega.dart';

void main() {
  test('Calcula correctamente el total de una entrega diaria y rango semanal', () {
    final entrega = Entrega(
      clienteId: 1,
      cantidadBotellas: 12,
      precioUnitario: 2.5,
      fecha: '2026-11-03',
    );

    expect(entrega.total, 30.0);

    final fecha = FechaSemanaUtils.desdeIso('2026-11-03');
    final lunes = FechaSemanaUtils.obtenerLunes(fecha);
    final domingo = FechaSemanaUtils.obtenerDomingo(fecha);

    expect(FechaSemanaUtils.aIso(lunes), '2026-11-02');
    expect(FechaSemanaUtils.aIso(domingo), '2026-11-08');
  });
}
