import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/entrega.dart';

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final ResumenClienteSemana resumen;
  final VoidCallback onVerDetalle;
  final VoidCallback onRegistrarEntrega;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.resumen,
    required this.onVerDetalle,
    required this.onRegistrarEntrega,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onVerDetalle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tel: ${cliente.telefono.isEmpty ? "Sin registrar" : cliente.telefono}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Ubicación: ${cliente.direccion.isEmpty ? "Sin registrar" : cliente.direccion}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (valor) {
                      if (valor == 'detalle') {
                        onVerDetalle();
                      } else if (valor == 'editar') {
                        onEditar();
                      } else if (valor == 'eliminar') {
                        onEliminar();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'detalle',
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 20,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text('Ver semana'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar cliente'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar cliente'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _DatoResumen(
                        etiqueta: 'Hoy',
                        jugos: '${FormatoUtils.entero(resumen.botellasHoy)} jugos',
                        dinero: FormatoUtils.moneda(resumen.totalHoy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatoResumen(
                        etiqueta: 'Semana',
                        jugos:
                            '${FormatoUtils.entero(resumen.botellasSemana)} jugos',
                        dinero: FormatoUtils.moneda(resumen.totalSemana),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatoResumen(
                        etiqueta: 'Mes',
                        jugos: '${FormatoUtils.entero(resumen.botellasMes)} jugos',
                        dinero: FormatoUtils.moneda(resumen.totalMes),
                        destacar: true,
                        alinearDerecha: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onVerDetalle,
                      icon: const Icon(Icons.calendar_view_week, size: 18),
                      label: const Text('Historial'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onRegistrarEntrega,
                      icon: const Icon(Icons.local_drink, size: 18),
                      label: const Text('Dejar jugos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final String etiqueta;
  final String jugos;
  final String dinero;
  final bool destacar;
  final bool alinearDerecha;

  const _DatoResumen({
    required this.etiqueta,
    required this.jugos,
    required this.dinero,
    this.destacar = false,
    this.alinearDerecha = false,
  });

  @override
  Widget build(BuildContext context) {
    final alineacion =
        alinearDerecha ? Alignment.centerRight : Alignment.centerLeft;

    return Column(
      crossAxisAlignment:
          alinearDerecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alineacion,
          child: Text(
            etiqueta,
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alineacion,
          child: Text(
            jugos,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alineacion,
          child: Text(
            dinero,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: destacar ? Colors.green.shade800 : Colors.deepOrange,
            ),
          ),
        ),
      ],
    );
  }
}
