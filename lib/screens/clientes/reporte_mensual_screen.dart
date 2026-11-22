import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/entrega.dart';

class ReporteMensualScreen extends StatefulWidget {
  const ReporteMensualScreen({super.key});

  @override
  State<ReporteMensualScreen> createState() => _ReporteMensualScreenState();
}

class _ReporteMensualScreenState extends State<ReporteMensualScreen> {
  late DateTime _mesSeleccionado;
  late Future<List<ReporteClienteMes>> _reporteFuture;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _mesSeleccionado = DateTime(ahora.year, ahora.month, 1);
    _cargarReporte();
  }

  bool get _esMesActual {
    final ahora = DateTime.now();
    return _mesSeleccionado.year == ahora.year &&
        _mesSeleccionado.month == ahora.month;
  }

  void _cargarReporte() {
    final inicio = FechaSemanaUtils.aIso(
      FechaSemanaUtils.obtenerInicioMes(_mesSeleccionado),
    );
    final fin = FechaSemanaUtils.aIso(
      FechaSemanaUtils.obtenerFinMes(_mesSeleccionado),
    );
    setState(() {
      _reporteFuture = DatabaseHelper.instance.getReporteMensualPorClientes(
        inicio,
        fin,
      );
    });
  }

  void _cambiarMes(int deltaMeses) {
    _mesSeleccionado = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + deltaMeses,
      1,
    );
    _cargarReporte();
  }

  @override
  Widget build(BuildContext context) {
    final inicioMes = FechaSemanaUtils.obtenerInicioMes(_mesSeleccionado);
    final finMes = FechaSemanaUtils.obtenerFinMes(_mesSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Mensual'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ReporteClienteMes>>(
        future: _reporteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final filas = snapshot.data ?? [];
          int totalDejadosMes = 0;
          int totalVendidosMes = 0;
          double totalDineroMes = 0.0;
          for (final item in filas) {
            totalDejadosMes += item.botellasDejadasMes;
            totalVendidosMes += item.botellasVendidasMes;
            totalDineroMes += item.totalMes;
          }

          return Column(
            children: [
              // Selector de mes
              Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      onPressed: () => _cambiarMes(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _esMesActual ? 'Mes Actual' : 'Mes Seleccionado',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              FechaSemanaUtils.formatearMesAnio(
                                _mesSeleccionado,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${FechaSemanaUtils.formatearCorto(inicioMes)} - ${FechaSemanaUtils.formatearCorto(finMes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (!_esMesActual)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                final ahora = DateTime.now();
                                _mesSeleccionado =
                                    DateTime(ahora.year, ahora.month, 1);
                                _cargarReporte();
                              },
                              child: const Text('Volver a este mes'),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mes siguiente',
                      onPressed: () => _cambiarMes(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Tarjeta Gran Total del Mes
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jugos Vendidos del Mes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${FormatoUtils.entero(totalVendidosMes)} vendidos',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Ingresos del Mes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  FormatoUtils.moneda(totalDineroMes),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jugos dejados en el mes: ${FormatoUtils.entero(totalDejadosMes)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Desglose mensual por cliente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: filas.isEmpty
                    ? const Center(
                        child: Text('No hay clientes registrados.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filas.length,
                        itemBuilder: (context, index) {
                          final item = filas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.nombreCliente,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${FormatoUtils.entero(item.botellasVendidasMes)} vendidos · ${FormatoUtils.entero(item.botellasDejadasMes)} dejados',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 140,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        FormatoUtils.moneda(item.totalMes),
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
