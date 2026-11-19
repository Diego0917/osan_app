import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';
import '../../models/entrega.dart';
import '../../widgets/cliente_card.dart';
import 'cliente_entregas_screen.dart';
import 'cliente_form_screen.dart';
import 'reporte_mensual_screen.dart';

class _DatosClientesSemana {
  final List<Cliente> clientes;
  final Map<int, ResumenClienteSemana> resumenes;

  const _DatosClientesSemana({
    required this.clientes,
    required this.resumenes,
  });
}

class ClientesListScreen extends StatefulWidget {
  const ClientesListScreen({super.key});

  @override
  State<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends State<ClientesListScreen> {
  late Future<_DatosClientesSemana> _datosFuture;

  @override
  void initState() {
    super.initState();
    _refreshClientes();
  }

  void _refreshClientes() {
    setState(() {
      _datosFuture = _cargarDatos();
    });
  }

  Future<_DatosClientesSemana> _cargarDatos() async {
    final ahora = DateTime.now();
    final lunes = FechaSemanaUtils.obtenerLunes(ahora);
    final domingo = FechaSemanaUtils.obtenerDomingo(ahora);
    final inicioMes = FechaSemanaUtils.obtenerInicioMes(ahora);
    final finMes = FechaSemanaUtils.obtenerFinMes(ahora);

    final clientes = await DatabaseHelper.instance.getClientes();
    final resumenes = await DatabaseHelper.instance.getResumenesSemanales(
      fechaInicio: FechaSemanaUtils.aIso(lunes),
      fechaFin: FechaSemanaUtils.aIso(domingo),
      fechaHoy: FechaSemanaUtils.aIso(ahora),
      fechaInicioMes: FechaSemanaUtils.aIso(inicioMes),
      fechaFinMes: FechaSemanaUtils.aIso(finMes),
    );

    return _DatosClientesSemana(clientes: clientes, resumenes: resumenes);
  }

  Future<void> _confirmarEliminarCliente(Cliente cliente) async {
    if (cliente.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Seguro que deseas eliminar a "${cliente.nombre}" y todo su historial de jugos entregados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.deleteCliente(cliente.id!);
      if (!mounted) return;
      _refreshClientes();
    }
  }

  Future<void> _abrirDetalleCliente(Cliente cliente) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteEntregasScreen(cliente: cliente),
      ),
    );
    if (!mounted) return;
    _refreshClientes();
  }

  Future<void> _abrirReporteMensual() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReporteMensualScreen(),
      ),
    );
    if (!mounted) return;
    _refreshClientes();
  }

  Future<void> _registrarEntrega(Cliente cliente) async {
    final guardado = await mostrarModalEntrega(context, cliente: cliente);
    if (!mounted) return;
    if (guardado) {
      _refreshClientes();
    }
  }

  Future<void> _abrirFormulario({Cliente? clienteExistente}) async {
    final guardado = await mostrarFormularioCliente(
      context,
      clienteExistente: clienteExistente,
    );
    if (!mounted) return;
    if (guardado) {
      _refreshClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final lunes = FechaSemanaUtils.obtenerLunes(ahora);
    final domingo = FechaSemanaUtils.obtenerDomingo(ahora);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes y Reparto'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Ver Reporte Mensual',
            onPressed: _abrirReporteMensual,
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      body: FutureBuilder<_DatosClientesSemana>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.clientes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay clientes registrados. Agrega el primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final clientes = snapshot.data!.clientes;
          final resumenes = snapshot.data!.resumenes;

          int botellasGlobalHoy = 0;
          double totalGlobalHoy = 0.0;
          int botellasGlobalSemana = 0;
          double totalGlobalSemana = 0.0;
          int botellasGlobalMes = 0;
          double totalGlobalMes = 0.0;

          for (final r in resumenes.values) {
            botellasGlobalHoy += r.botellasHoy;
            totalGlobalHoy += r.totalHoy;
            botellasGlobalSemana += r.botellasSemana;
            totalGlobalSemana += r.totalSemana;
            botellasGlobalMes += r.botellasMes;
            totalGlobalMes += r.totalMes;
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(14),
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
                                'Resumen General de Ingresos',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Semana: ${FechaSemanaUtils.formatearCorto(lunes)} - ${FechaSemanaUtils.formatearCorto(domingo)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _abrirReporteMensual,
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text(
                            'Reporte Mes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CajaResumenGlobal(
                            titulo: 'Total del Día',
                            jugos:
                                '${FormatoUtils.entero(botellasGlobalHoy)} jugos',
                            monto: FormatoUtils.moneda(totalGlobalHoy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CajaResumenGlobal(
                            titulo: 'Semana Actual',
                            jugos:
                                '${FormatoUtils.entero(botellasGlobalSemana)} jugos',
                            monto: FormatoUtils.moneda(totalGlobalSemana),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CajaResumenGlobal(
                            titulo: FechaSemanaUtils.meses[ahora.month - 1],
                            jugos:
                                '${FormatoUtils.entero(botellasGlobalMes)} jugos',
                            monto: FormatoUtils.moneda(totalGlobalMes),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    final resumen =
                        resumenes[cliente.id] ?? const ResumenClienteSemana();

                    return ClienteCard(
                      cliente: cliente,
                      resumen: resumen,
                      onVerDetalle: () => _abrirDetalleCliente(cliente),
                      onRegistrarEntrega: () => _registrarEntrega(cliente),
                      onEditar: () =>
                          _abrirFormulario(clienteExistente: cliente),
                      onEliminar: () => _confirmarEliminarCliente(cliente),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class _CajaResumenGlobal extends StatelessWidget {
  final String titulo;
  final String jugos;
  final String monto;

  const _CajaResumenGlobal({
    required this.titulo,
    required this.jugos,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              titulo,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              jugos,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              monto,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
