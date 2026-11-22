import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/entrega.dart';

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final ResumenClienteSemana resumen;
  final VoidCallback onAbrirDejados;
  final VoidCallback onAbrirVendidos;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.resumen,
    required this.onAbrirDejados,
    required this.onAbrirVendidos,
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
        onTap: onAbrirDejados,
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
                      if (valor == 'dejados') {
                        onAbrirDejados();
                      } else if (valor == 'vendidos') {
                        onAbrirVendidos();
                      } else if (valor == 'editar') {
                        onEditar();
                      } else if (valor == 'eliminar') {
                        onEliminar();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'dejados',
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_drink,
                              size: 20,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text('Jugos dejados'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'vendidos',
                        child: Row(
                          children: [
                            Icon(
                              Icons.sell,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text('Jugos vendidos'),
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
                        jugos:
                            'Dej: ${FormatoUtils.entero(resumen.botellasDejadasHoy)} · Ven: ${FormatoUtils.entero(resumen.botellasVendidasHoy)}',
                        dinero: FormatoUtils.moneda(resumen.totalHoy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatoResumen(
                        etiqueta: 'Semana',
                        jugos:
                            'Dej: ${FormatoUtils.entero(resumen.botellasDejadasSemana)} · Ven: ${FormatoUtils.entero(resumen.botellasVendidasSemana)}',
                        dinero: FormatoUtils.moneda(resumen.totalSemana),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DatoResumen(
                        etiqueta: 'Mes',
                        jugos:
                            'Dej: ${FormatoUtils.entero(resumen.botellasDejadasMes)} · Ven: ${FormatoUtils.entero(resumen.botellasVendidasMes)}',
                        dinero: FormatoUtils.moneda(resumen.totalMes),
                        destacar: true,
                        alinearDerecha: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: onAbrirDejados,
                      icon: const Icon(Icons.local_drink, size: 17),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Jugos dejados',
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: onAbrirVendidos,
                      icon: const Icon(Icons.sell, size: 17),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Jugos vendidos',
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
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
