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
  bool descontarInventario = false;
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  label: Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Fecha: ${FechaSemanaUtils.formatearConDia(FechaSemanaUtils.aIso(fechaSeleccionada))}',
                      ),
                    ),
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
                      'Descontar del contador de "Jugos del día"',
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
                    children: [
                      const Text(
                        'Valor total del día:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            FormatoUtils.moneda(subtotal),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
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
          '¿Eliminar la entrega de ${FormatoUtils.entero(entrega.cantidadBotellas)} botellas del ${FechaSemanaUtils.formatearConDia(entrega.fecha)}?',
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
        title: Text(
          widget.cliente.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          double totalDineroHoy = 0.0;
          double totalDineroSemana = 0.0;

          for (final e in entregas) {
            totalBotellasSemana += e.cantidadBotellas;
            totalDineroSemana += e.total;
            if (e.fecha == hoyIso) {
              botellasHoy += e.cantidadBotellas;
              totalDineroHoy += e.total;
            }
          }

          return Column(
            children: [
              // Selector de semana
              Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Semana anterior',
                      onPressed: () => _cambiarSemana(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${FechaSemanaUtils.formatearCorto(_lunesSeleccionado)} - ${FechaSemanaUtils.formatearCorto(_domingoSeleccionado)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
                                    FechaSemanaUtils.obtenerLunes(
                                      DateTime.now(),
                                    );
                                _cargarEntregas();
                              },
                              child: const Text('Volver a esta semana'),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Semana siguiente',
                      onPressed: () => _cambiarSemana(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Resumen acumulado de hoy y de la semana
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      if (_esSemanaActual) ...[
                        Expanded(
                          child: _ColumnaResumenSemana(
                            titulo: 'Total del Día',
                            valorPrincipal: FormatoUtils.moneda(totalDineroHoy),
                            subtitulo:
                                '${FormatoUtils.entero(botellasHoy)} botellas hoy',
                            colorValor: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: _ColumnaResumenSemana(
                          titulo: 'Jugos Semana',
                          valorPrincipal:
                              FormatoUtils.entero(totalBotellasSemana),
                          subtitulo: 'botellas',
                          colorValor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ColumnaResumenSemana(
                          titulo: 'Total Semana',
                          valorPrincipal:
                              FormatoUtils.moneda(totalDineroSemana),
                          subtitulo: 'a cobrar',
                          colorValor: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de entregas diarias de la semana
              Expanded(
                child: entregas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay jugos registrados en esta semana.',
                            textAlign: TextAlign.center,
                          ),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.orange.shade100,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              FormatoUtils.entero(
                                                entrega.cantidadBotellas,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              FechaSemanaUtils.formatearConDia(
                                                entrega.fecha,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${FormatoUtils.entero(entrega.cantidadBotellas)} botellas × ${FormatoUtils.moneda(entrega.precioUnitario)} c/u',
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
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Valor total del día:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              FormatoUtils.moneda(entrega.total),
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

class _ColumnaResumenSemana extends StatelessWidget {
  final String titulo;
  final String valorPrincipal;
  final String subtitulo;
  final Color colorValor;

  const _ColumnaResumenSemana({
    required this.titulo,
    required this.valorPrincipal,
    required this.subtitulo,
    required this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            titulo,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valorPrincipal,
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorValor,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            subtitulo,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
