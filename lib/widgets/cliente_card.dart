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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tel: ${cliente.telefono.isEmpty ? "Sin registrar" : cliente.telefono}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Ubicación: ${cliente.direccion.isEmpty ? "Sin registrar" : cliente.direccion}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
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
                            Icon(Icons.receipt_long, size: 20, color: Colors.orange),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DatoResumen(
                      etiqueta: 'Hoy',
                      valor: '${resumen.botellasHoy} jugos',
                    ),
                    _DatoResumen(
                      etiqueta: 'Semana',
                      valor: '${resumen.botellasSemana} jugos',
                    ),
                    _DatoResumen(
                      etiqueta: 'Total semana',
                      valor: '\$${resumen.totalSemana.toStringAsFixed(2)}',
                      destacar: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onVerDetalle,
                    icon: const Icon(Icons.calendar_view_week, size: 18),
                    label: const Text('Historial'),
                  ),
                  const SizedBox(width: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacar;

  const _DatoResumen({
    required this.etiqueta,
    required this.valor,
    this.destacar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: destacar ? Colors.green.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

