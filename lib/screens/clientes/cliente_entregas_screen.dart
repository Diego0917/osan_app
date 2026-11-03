import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';
import '../../models/entrega.dart';

Future<bool> mostrarModalEntrega(
  BuildContext context, {
  required Cliente cliente,
  Entrega? entregaExistente,
}) async {
  if (cliente.id == null) return false;

  final esEdicion = entregaExistente != null;
  double? precioSugerido;
  if (!esEdicion) {
    precioSugerido =
        await DatabaseHelper.instance.getUltimoPrecioSugerido(cliente.id!);
    if (!context.mounted) return false;
  }

  final controllerCantidad = TextEditingController(
    text: esEdicion ? '${entregaExistente.cantidadBotellas}' : '',
  );
  final controllerPrecio = TextEditingController(
    text: esEdicion
        ? entregaExistente.precioUnitario.toStringAsFixed(2)
        : (precioSugerido != null ? precioSugerido.toStringAsFixed(2) : ''),
  );

  DateTime fechaSeleccionada = esEdicion
      ? FechaSemanaUtils.desdeIso(entregaExistente.fecha)
      : DateTime.now();
  bool descontarInventario = true;
  String? errorValidacion;

  double calcularSubtotal() {
    final cant = int.tryParse(controllerCantidad.text.trim()) ?? 0;
    final precio = double.tryParse(
          controllerPrecio.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
    if (cant <= 0 || precio < 0) return 0.0;
    return cant * precio;
  }

  final resultado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final subtotal = calcularSubtotal();

        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  esEdicion
                      ? 'Editar entrega - ${cliente.nombre}'
                      : 'Dejar jugos a ${cliente.nombre}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nuevaFecha = await showDatePicker(
                      context: ctx,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (nuevaFecha != null) {
                      setModalState(() {
                        fechaSeleccionada = nuevaFecha;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Fecha: ${FechaSemanaUtils.formatearConDia(FechaSemanaUtils.aIso(fechaSeleccionada))}',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controllerCantidad,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {
                    errorValidacion = null;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de botellas dejadas *',
                    prefixIcon: Icon(Icons.local_drink),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controllerPrecio,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setModalState(() {
                    errorValidacion = null;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Precio por botella (\$) *',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!esEdicion) ...[
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Descontar del inventario de "Botellas"',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: descontarInventario,
                    onChanged: (valor) {
                      setModalState(() {
                        descontarInventario = valor;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total del día:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (errorValidacion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorValidacion!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final cantidad =
                        int.tryParse(controllerCantidad.text.trim()) ?? 0;
                    final precio = double.tryParse(
                      controllerPrecio.text.trim().replaceAll(',', '.'),
                    );

                    if (cantidad <= 0) {
                      setModalState(() {
                        errorValidacion =
                            'Ingresa una cantidad válida mayor a 0.';
                      });
                      return;
                    }
                    if (precio == null || precio < 0) {
                      setModalState(() {
                        errorValidacion = 'Ingresa un precio válido.';
                      });
                      return;
                    }

                    final entrega = Entrega(
                      id: entregaExistente?.id,
                      clienteId: cliente.id!,
                      cantidadBotellas: cantidad,
                      precioUnitario: precio,
                      total: cantidad * precio,
                      fecha: FechaSemanaUtils.aIso(fechaSeleccionada),
                    );

                    if (esEdicion) {
                      await DatabaseHelper.instance.updateEntrega(entrega);
                    } else {
                      await DatabaseHelper.instance.insertEntrega(
                        entrega,
                        descontarDeInventario: descontarInventario,
                      );
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(
                    esEdicion ? 'Actualizar Entrega' : 'Guardar Entrega',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  return resultado == true;
}

class ClienteEntregasScreen extends StatefulWidget {
  final Cliente cliente;

  const ClienteEntregasScreen({super.key, required this.cliente});

  @override
  State<ClienteEntregasScreen> createState() => _ClienteEntregasScreenState();
}

class _ClienteEntregasScreenState extends State<ClienteEntregasScreen> {
  late DateTime _lunesSeleccionado;
  late Future<List<Entrega>> _entregasFuture;

  @override
  void initState() {
    super.initState();
    _lunesSeleccionado = FechaSemanaUtils.obtenerLunes(DateTime.now());
    _cargarEntregas();
  }

  DateTime get _domingoSeleccionado =>
      FechaSemanaUtils.obtenerDomingo(_lunesSeleccionado);

  bool get _esSemanaActual {
    final lunesActual = FechaSemanaUtils.obtenerLunes(DateTime.now());
    return FechaSemanaUtils.aIso(_lunesSeleccionado) ==
        FechaSemanaUtils.aIso(lunesActual);
  }

  void _cargarEntregas() {
    final inicio = FechaSemanaUtils.aIso(_lunesSeleccionado);
    final fin = FechaSemanaUtils.aIso(_domingoSeleccionado);
    setState(() {
      _entregasFuture = DatabaseHelper.instance.getEntregasPorClienteYRango(
        widget.cliente.id!,
        inicio,
        fin,
      );
    });
  }

  void _cambiarSemana(int desplazamientoSemanas) {
    _lunesSeleccionado = DateTime(
      _lunesSeleccionado.year,
      _lunesSeleccionado.month,
      _lunesSeleccionado.day + (desplazamientoSemanas * 7),
    );
    _cargarEntregas();
  }

  Future<void> _abrirFormularioEntrega({Entrega? entregaExistente}) async {
    final guardado = await mostrarModalEntrega(
      context,
      cliente: widget.cliente,
      entregaExistente: entregaExistente,
    );
    if (!mounted) return;
    if (guardado) {
      _cargarEntregas();
    }
  }

  Future<void> _confirmarEliminarEntrega(Entrega entrega) async {
    if (entrega.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar la entrega de ${entrega.cantidadBotellas} botellas del ${FechaSemanaUtils.formatearConDia(entrega.fecha)}?',
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
      await DatabaseHelper.instance.deleteEntrega(entrega.id!);
      if (!mounted) return;
      _cargarEntregas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoyIso = FechaSemanaUtils.aIso(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente.nombre),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Entrega>>(
        future: _entregasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entregas = snapshot.data ?? [];
          int totalBotellasSemana = 0;
          int botellasHoy = 0;
          double totalDineroSemana = 0.0;

          for (final e in entregas) {
            totalBotellasSemana += e.cantidadBotellas;
            totalDineroSemana += e.total;
            if (e.fecha == hoyIso) {
              botellasHoy += e.cantidadBotellas;
            }
          }

          return Column(
            children: [
              // Selector de semana
              Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Semana anterior',
                      onPressed: () => _cambiarSemana(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Column(
                      children: [
                        Text(
                          _esSemanaActual
                              ? 'Semana Actual'
                              : 'Semana Seleccionada',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Text(
                          '${FechaSemanaUtils.formatearCorto(_lunesSeleccionado)} - ${FechaSemanaUtils.formatearCorto(_domingoSeleccionado)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_esSemanaActual)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _lunesSeleccionado =
                                  FechaSemanaUtils.obtenerLunes(DateTime.now());
                              _cargarEntregas();
                            },
                            child: const Text('Volver a esta semana'),
                          ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Semana siguiente',
                      onPressed: () => _cambiarSemana(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Resumen acumulado de la semana
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (_esSemanaActual)
                        Column(
                          children: [
                            const Text(
                              'Dejados hoy',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$botellasHoy',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'botellas',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      Column(
                        children: [
                          const Text(
                            'Total Semana',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalBotellasSemana',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'botellas',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Total a Cobrar',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalDineroSemana.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const Text(
                            'en la semana',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de entregas diarias de la semana
              Expanded(
                child: entregas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay jugos registrados en esta semana.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: entregas.length,
                        itemBuilder: (context, index) {
                          final entrega = entregas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Text(
                                  '${entrega.cantidadBotellas}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              title: Text(
                                FechaSemanaUtils.formatearConDia(entrega.fecha),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${entrega.cantidadBotellas} botellas × \$${entrega.precioUnitario.toStringAsFixed(2)} c/u',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${entrega.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (valor) {
                                      if (valor == 'editar') {
                                        _abrirFormularioEntrega(
                                          entregaExistente: entrega,
                                        );
                                      } else if (valor == 'eliminar') {
                                        _confirmarEliminarEntrega(entrega);
                                      }
                                    },
                                    itemBuilder: (ctx) => const [
                                      PopupMenuItem(
                                        value: 'editar',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'eliminar',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Eliminar'),
                                          ],
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormularioEntrega(),
        icon: const Icon(Icons.add),
        label: const Text('Dejar jugos'),
      ),
    );
  }
}
