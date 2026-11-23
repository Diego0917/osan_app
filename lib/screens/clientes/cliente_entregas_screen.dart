import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';
import '../../models/entrega.dart';

Future<bool> mostrarModalEntrega(
  BuildContext context, {
  required Cliente cliente,
  TipoEntrega tipo = TipoEntrega.dejado,
  Entrega? entregaExistente,
}) async {
  if (cliente.id == null) return false;

  final esEdicion = entregaExistente != null;
  final tipoEfectivo = entregaExistente?.tipo ?? tipo;
  final esDejado = tipoEfectivo == TipoEntrega.dejado;

  double? precioSugerido;
  if (!esEdicion && !esDejado) {
    precioSugerido =
        await DatabaseHelper.instance.getUltimoPrecioSugerido(cliente.id!);
    if (!context.mounted) return false;
  }

  final controllerCantidad = TextEditingController(
    text: entregaExistente != null ? '${entregaExistente.cantidadBotellas}' : '',
  );
  final controllerPrecio = TextEditingController(
    text: esDejado
        ? ''
        : (entregaExistente != null
            ? entregaExistente.precioUnitario.toStringAsFixed(2)
            : (precioSugerido != null
                ? precioSugerido.toStringAsFixed(2)
                : '')),
  );

  DateTime fechaSeleccionada = entregaExistente != null
      ? FechaSemanaUtils.desdeIso(entregaExistente.fecha)
      : DateTime.now();
  String? errorValidacion;

  double calcularSubtotal() {
    if (esDejado) return 0.0;
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
    builder: (ctx) => _AutoDisposeModal(
      controllers: [controllerCantidad, controllerPrecio],
      child: StatefulBuilder(
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
                    esDejado
                        ? (esEdicion
                            ? 'Editar jugos dejados - ${cliente.nombre}'
                            : 'Jugos dejados a ${cliente.nombre}')
                        : (esEdicion
                            ? 'Editar jugos vendidos - ${cliente.nombre}'
                            : 'Jugos vendidos - ${cliente.nombre}'),
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
                    decoration: InputDecoration(
                      labelText: esDejado
                          ? 'Cantidad de jugos dejados *'
                          : 'Cantidad de jugos vendidos *',
                      prefixIcon: Icon(
                        esDejado ? Icons.local_drink : Icons.sell,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (!esDejado) ...[
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
                    const SizedBox(height: 10),
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
                  ],
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

                      if (cantidad <= 0) {
                        setModalState(() {
                          errorValidacion =
                              'Ingresa una cantidad válida mayor a 0.';
                        });
                        return;
                      }

                      double precioFinal = 0.0;
                      if (!esDejado) {
                        final precio = double.tryParse(
                          controllerPrecio.text.trim().replaceAll(',', '.'),
                        );
                        if (precio == null || precio < 0) {
                          setModalState(() {
                            errorValidacion = 'Ingresa un precio válido.';
                          });
                          return;
                        }
                        precioFinal = precio;
                      }

                      final entrega = Entrega(
                        id: entregaExistente?.id,
                        clienteId: cliente.id!,
                        cantidadBotellas: cantidad,
                        precioUnitario: precioFinal,
                        total: esDejado ? 0.0 : (cantidad * precioFinal),
                        fecha: FechaSemanaUtils.aIso(fechaSeleccionada),
                        tipo: tipoEfectivo,
                      );

                      if (esEdicion) {
                        await DatabaseHelper.instance.updateEntrega(entrega);
                      } else {
                        await DatabaseHelper.instance.insertEntrega(entrega);
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx, true);
                    },
                    child: Text(
                      esDejado
                          ? (esEdicion
                              ? 'Actualizar Jugos Dejados'
                              : 'Guardar Jugos Dejados')
                          : (esEdicion
                              ? 'Actualizar Jugos Vendidos'
                              : 'Guardar Jugos Vendidos'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  return resultado == true;
}

class _AutoDisposeModal extends StatefulWidget {
  final List<ChangeNotifier> controllers;
  final Widget child;

  const _AutoDisposeModal({
    required this.controllers,
    required this.child,
  });

  @override
  State<_AutoDisposeModal> createState() => _AutoDisposeModalState();
}

class _AutoDisposeModalState extends State<_AutoDisposeModal> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ClienteEntregasScreen extends StatefulWidget {
  final Cliente cliente;
  final TipoEntrega pestanaInicial;

  const ClienteEntregasScreen({
    super.key,
    required this.cliente,
    this.pestanaInicial = TipoEntrega.dejado,
  });

  @override
  State<ClienteEntregasScreen> createState() => _ClienteEntregasScreenState();
}

class _ClienteEntregasScreenState extends State<ClienteEntregasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late DateTime _lunesSeleccionado;
  late Future<List<Entrega>> _entregasFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.pestanaInicial == TipoEntrega.vendido ? 1 : 0,
    );
    _tabController.addListener(_onCambioPestana);
    _lunesSeleccionado = FechaSemanaUtils.obtenerLunes(DateTime.now());
    _cargarEntregas();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onCambioPestana);
    _tabController.dispose();
    super.dispose();
  }

  void _onCambioPestana() {
    if (!mounted) return;
    setState(() {});
  }

  TipoEntrega get _tipoActual =>
      _tabController.index == 1 ? TipoEntrega.vendido : TipoEntrega.dejado;

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

  Future<void> _abrirFormularioEntrega({
    TipoEntrega? tipo,
    Entrega? entregaExistente,
  }) async {
    final guardado = await mostrarModalEntrega(
      context,
      cliente: widget.cliente,
      tipo: entregaExistente?.tipo ?? tipo ?? _tipoActual,
      entregaExistente: entregaExistente,
    );
    if (!mounted) return;
    if (guardado) {
      _cargarEntregas();
    }
  }

  Future<void> _confirmarEliminarEntrega(Entrega entrega) async {
    if (entrega.id == null) return;
    final etiquetaTipo = entrega.tipo == TipoEntrega.dejado
        ? 'jugos dejados'
        : 'jugos vendidos';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar el registro de ${FormatoUtils.entero(entrega.cantidadBotellas)} $etiquetaTipo del ${FechaSemanaUtils.formatearConDia(entrega.fecha)}?',
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

  Widget _buildTabDejados(List<Entrega> dejados, String hoyIso) {
    int dejadosHoy = 0;
    int dejadosSemana = 0;
    for (final e in dejados) {
      dejadosSemana += e.cantidadBotellas;
      if (e.fecha == hoyIso) {
        dejadosHoy += e.cantidadBotellas;
      }
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                if (_esSemanaActual) ...[
                  Expanded(
                    child: _ColumnaResumenSemana(
                      titulo: 'Dejados Hoy',
                      valorPrincipal: FormatoUtils.entero(dejadosHoy),
                      subtitulo: 'botellas hoy',
                      colorValor: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _ColumnaResumenSemana(
                    titulo: 'Dejados Semana',
                    valorPrincipal: FormatoUtils.entero(dejadosSemana),
                    subtitulo: 'botellas dejadas',
                    colorValor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: dejados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay jugos dejados registrados en esta semana.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 84),
                  itemCount: dejados.length,
                  itemBuilder: (context, index) {
                    final entrega = dejados[index];
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
                        child: Row(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '${FormatoUtils.entero(entrega.cantidadBotellas)} jugos dejados',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildMenuAccionesEntrega(entrega),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabVendidos(List<Entrega> vendidos, String hoyIso) {
    int totalBotellasSemana = 0;
    int botellasHoy = 0;
    double totalDineroHoy = 0.0;
    double totalDineroSemana = 0.0;

    for (final e in vendidos) {
      totalBotellasSemana += e.cantidadBotellas;
      totalDineroSemana += e.total;
      if (e.fecha == hoyIso) {
        botellasHoy += e.cantidadBotellas;
        totalDineroHoy += e.total;
      }
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                if (_esSemanaActual) ...[
                  Expanded(
                    child: _ColumnaResumenSemana(
                      titulo: 'Total del Día',
                      valorPrincipal: FormatoUtils.moneda(totalDineroHoy),
                      subtitulo:
                          '${FormatoUtils.entero(botellasHoy)} vendidos hoy',
                      colorValor: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _ColumnaResumenSemana(
                    titulo: 'Vendidos Semana',
                    valorPrincipal: FormatoUtils.entero(totalBotellasSemana),
                    subtitulo: 'botellas',
                    colorValor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ColumnaResumenSemana(
                    titulo: 'Total Semana',
                    valorPrincipal: FormatoUtils.moneda(totalDineroSemana),
                    subtitulo: 'a cobrar',
                    colorValor: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: vendidos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay jugos vendidos registrados en esta semana.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 84),
                  itemCount: vendidos.length,
                  itemBuilder: (context, index) {
                    final entrega = vendidos[index];
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
                                  backgroundColor: Colors.green.shade100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        FormatoUtils.entero(
                                          entrega.cantidadBotellas,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
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
                                _buildMenuAccionesEntrega(entrega),
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
  }

  Widget _buildMenuAccionesEntrega(Entrega entrega) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (valor) {
        if (valor == 'editar') {
          _abrirFormularioEntrega(entregaExistente: entrega);
        } else if (valor == 'eliminar') {
          _confirmarEliminarEntrega(entrega);
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoyIso = FechaSemanaUtils.aIso(DateTime.now());
    final enPestanaVendidos = _tipoActual == TipoEntrega.vendido;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cliente.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.local_drink), text: 'Jugos dejados'),
            Tab(icon: Icon(Icons.sell), text: 'Jugos vendidos'),
          ],
        ),
      ),
      body: FutureBuilder<List<Entrega>>(
        future: _entregasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entregas = snapshot.data ?? [];
          final dejados = entregas
              .where((e) => e.tipo == TipoEntrega.dejado)
              .toList();
          final vendidos = entregas
              .where((e) => e.tipo == TipoEntrega.vendido)
              .toList();

          return Column(
            children: [
              // Selector de semana compartido por ambas pestañas
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabDejados(dejados, hoyIso),
                    _buildTabVendidos(vendidos, hoyIso),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormularioEntrega(tipo: _tipoActual),
        icon: Icon(enPestanaVendidos ? Icons.sell : Icons.local_drink),
        label: Text(
          enPestanaVendidos ? 'Registrar vendidos' : 'Dejar jugos',
        ),
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
