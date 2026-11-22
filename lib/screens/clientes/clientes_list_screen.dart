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
  final TextEditingController _searchController = TextEditingController();
  String _queryBusqueda = '';

  @override
  void initState() {
    super.initState();
    _refreshClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizarTexto(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
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

  Future<void> _abrirDetalleCliente(
    Cliente cliente, {
    TipoEntrega pestanaInicial = TipoEntrega.dejado,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteEntregasScreen(
          cliente: cliente,
          pestanaInicial: pestanaInicial,
        ),
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

          int vendidosGlobalHoy = 0;
          double totalGlobalHoy = 0.0;
          int vendidosGlobalSemana = 0;
          double totalGlobalSemana = 0.0;
          int vendidosGlobalMes = 0;
          double totalGlobalMes = 0.0;

          for (final r in resumenes.values) {
            vendidosGlobalHoy += r.botellasVendidasHoy;
            totalGlobalHoy += r.totalHoy;
            vendidosGlobalSemana += r.botellasVendidasSemana;
            totalGlobalSemana += r.totalSemana;
            vendidosGlobalMes += r.botellasVendidasMes;
            totalGlobalMes += r.totalMes;
          }

          final queryNormalizado = _normalizarTexto(_queryBusqueda);
          final clientesFiltrados = queryNormalizado.isEmpty
              ? clientes
              : clientes
                  .where(
                    (c) => _normalizarTexto(c.nombre).contains(queryNormalizado),
                  )
                  .toList();

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
                                '${FormatoUtils.entero(vendidosGlobalHoy)} vend.',
                            monto: FormatoUtils.moneda(totalGlobalHoy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CajaResumenGlobal(
                            titulo: 'Semana Actual',
                            jugos:
                                '${FormatoUtils.entero(vendidosGlobalSemana)} vend.',
                            monto: FormatoUtils.moneda(totalGlobalSemana),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CajaResumenGlobal(
                            titulo: FechaSemanaUtils.meses[ahora.month - 1],
                            jugos:
                                '${FormatoUtils.entero(vendidosGlobalMes)} vend.',
                            monto: FormatoUtils.moneda(totalGlobalMes),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (valor) {
                    setState(() {
                      _queryBusqueda = valor;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nombre...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryBusqueda.isNotEmpty
                        ? IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _queryBusqueda = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: clientesFiltrados.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No se encontraron clientes para "${_queryBusqueda.trim()}".',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _queryBusqueda = '';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar búsqueda'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = clientesFiltrados[index];
                          final resumen =
                              resumenes[cliente.id] ??
                              const ResumenClienteSemana();

                          return ClienteCard(
                            cliente: cliente,
                            resumen: resumen,
                            onAbrirDejados: () => _abrirDetalleCliente(
                              cliente,
                              pestanaInicial: TipoEntrega.dejado,
                            ),
                            onAbrirVendidos: () => _abrirDetalleCliente(
                              cliente,
                              pestanaInicial: TipoEntrega.vendido,
                            ),
                            onEditar: () =>
                                _abrirFormulario(clienteExistente: cliente),
                            onEliminar: () =>
                                _confirmarEliminarCliente(cliente),
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
