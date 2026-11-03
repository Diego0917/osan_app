import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';
import '../../models/entrega.dart';
import '../../widgets/cliente_card.dart';
import 'cliente_entregas_screen.dart';
import 'cliente_form_screen.dart';

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

    final clientes = await DatabaseHelper.instance.getClientes();
    final resumenes = await DatabaseHelper.instance.getResumenesSemanales(
      fechaInicio: FechaSemanaUtils.aIso(lunes),
      fechaFin: FechaSemanaUtils.aIso(domingo),
      fechaHoy: FechaSemanaUtils.aIso(ahora),
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
        title: const Text('Clientes y Reparto Semanal'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_DatosClientesSemana>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.clientes.isEmpty) {
            return const Center(
              child: Text('No hay clientes registrados. Agrega el primero.'),
            );
          }

          final clientes = snapshot.data!.clientes;
          final resumenes = snapshot.data!.resumenes;

          int botellasGlobalSemana = 0;
          double totalGlobalSemana = 0.0;
          for (final r in resumenes.values) {
            botellasGlobalSemana += r.botellasSemana;
            totalGlobalSemana += r.totalSemana;
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen General (Semana Actual)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${FechaSemanaUtils.formatearCorto(lunes)} - ${FechaSemanaUtils.formatearCorto(domingo)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$botellasGlobalSemana jugos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '\$${totalGlobalSemana.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
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
