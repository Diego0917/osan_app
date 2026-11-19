import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/entrega.dart';
import '../../models/productos.dart';
import '../../widgets/producto_card.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _refreshInventario();
  }

  void _refreshInventario() {
    setState(() {
      _productosFuture = DatabaseHelper.instance.getProductos();
    });
  }

  Future<void> _modificarCantidad(Producto producto, int cambio) async {
    final nuevaCantidad = producto.cantidad + cambio;
    if (nuevaCantidad < 0) return;

    final actualizado = Producto(
      id: producto.id,
      nombre: producto.nombre,
      cantidad: nuevaCantidad,
    );

    await DatabaseHelper.instance.updateProducto(
      actualizado,
      cantidadAnterior: producto.cantidad,
    );
    if (!mounted) return;
    _refreshInventario();
  }

  Future<void> _cerrarJornadaTarde() async {
    await DatabaseHelper.instance.cerrarJornadaTarde();
    if (!mounted) return;
    _refreshInventario();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tarde cerrada: Jugos y Devoluciones puestos en 0 (Botellas y Vendidas se mantienen).',
        ),
      ),
    );
  }

  Future<void> _ponerEnCeroIndividual(Producto producto) async {
    await DatabaseHelper.instance.ponerProductoEnCeroPorNombre(producto.nombre);
    if (!mounted) return;
    _refreshInventario();
  }

  void _mostrarModalHacerJugos({
    required int stockBotellas,
    required int stockJugos,
    required int stockVendidas,
  }) {
    final controllerCantidad = TextEditingController();
    String? mensajeError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cant = int.tryParse(controllerCantidad.text.trim()) ?? 0;
          final cantValida = cant > 0 ? cant : 0;
          final nuevasBotellas =
              (stockBotellas - cantValida) < 0 ? 0 : (stockBotellas - cantValida);
          final nuevosJugos = stockJugos + cantValida;
          final nuevasVendidas = stockVendidas + cantValida;

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
                  const Text(
                    'Hacer Jugos (Noche / Mañana)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Se restarán de tus Botellas disponibles y saldrán a venta. Las que regresen luego como devolución se restarán de Botellas vendidas.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controllerCantidad,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {
                      mensajeError = null;
                    }),
                    decoration: InputDecoration(
                      labelText: 'Cantidad de jugos hechos *',
                      prefixIcon: const Icon(Icons.local_drink),
                      errorText: mensajeError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Botellas en casa:',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${FormatoUtils.entero(stockBotellas)} → ${FormatoUtils.entero(nuevasBotellas)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Jugos del día:',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${FormatoUtils.entero(stockJugos)} → ${FormatoUtils.entero(nuevosJugos)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Botellas vendidas (en calle):',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${FormatoUtils.entero(stockVendidas)} → ${FormatoUtils.entero(nuevasVendidas)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
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
                          mensajeError = 'Ingresa una cantidad mayor a 0.';
                        });
                        return;
                      }
                      if (stockBotellas > 0 && cantidad > stockBotellas) {
                        setModalState(() {
                          mensajeError =
                              'Solo tienes ${FormatoUtils.entero(stockBotellas)} botellas disponibles.';
                        });
                        return;
                      }

                      await DatabaseHelper.instance.producirJugos(cantidad);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        _refreshInventario();
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Registrar Jugos Preparados'),
                  ),
                  if (stockJugos > 0) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await DatabaseHelper.instance
                            .ponerProductoEnCeroPorNombre('jugos');
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          _refreshInventario();
                        }
                      },
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text(
                        'Poner Jugos en 0 (Cierre de tarde)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalCargarDevoluciones({
    required int stockBotellas,
    required int stockDevoluciones,
    required int stockVendidas,
  }) {
    final controllerCantidad = TextEditingController();
    String? mensajeError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cant = int.tryParse(controllerCantidad.text.trim()) ?? 0;
          final cantValida = cant > 0 ? cant : 0;
          final nuevasBotellas = stockBotellas + cantValida;
          final nuevasVendidas =
              (stockVendidas - cantValida) < 0 ? 0 : (stockVendidas - cantValida);

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
                  const Text(
                    'Cargar Devoluciones (Mañana)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Las botellas devueltas se suman a tus Botellas disponibles para reutilizarse, y las que no regresaron quedan en Botellas vendidas.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controllerCantidad,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {
                      mensajeError = null;
                    }),
                    decoration: InputDecoration(
                      labelText: 'Botellas devueltas recogidas esta mañana *',
                      prefixIcon: const Icon(Icons.autorenew),
                      errorText: mensajeError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Botellas disponibles (se suman):',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${FormatoUtils.entero(stockBotellas)} → ${FormatoUtils.entero(nuevasBotellas)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Botellas vendidas (no regresaron):',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${FormatoUtils.entero(stockVendidas)} → ${FormatoUtils.entero(nuevasVendidas)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final cantidad =
                          int.tryParse(controllerCantidad.text.trim()) ?? 0;
                      if (cantidad <= 0) {
                        setModalState(() {
                          mensajeError = 'Ingresa una cantidad mayor a 0.';
                        });
                        return;
                      }

                      await DatabaseHelper.instance
                          .registrarDevoluciones(cantidad);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        _refreshInventario();
                      }
                    },
                    icon: const Icon(Icons.add_task),
                    label: const Text('Cargar y Sumar a Botellas'),
                  ),
                  if (stockDevoluciones > 0) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await DatabaseHelper.instance
                            .reiniciarContadorDevoluciones();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          _refreshInventario();
                        }
                      },
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text(
                        'Poner Devoluciones en 0 (sin restar Botellas)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalFormularioProducto({Producto? productoExistente}) {
    final esEdicion = productoExistente != null;
    final controllerNombre = TextEditingController(
      text: productoExistente?.nombre ?? '',
    );
    final controllerCantidad = TextEditingController(
      text: productoExistente != null ? '${productoExistente.cantidad}' : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                    ? 'Editar Producto / Insumo'
                    : 'Agregar Nuevo Producto / Insumo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controllerNombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controllerCantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad en stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final nombre = controllerNombre.text.trim();
                  final cantidadParsed =
                      int.tryParse(controllerCantidad.text) ?? 0;
                  final cantidad = cantidadParsed < 0 ? 0 : cantidadParsed;

                  if (nombre.isEmpty) return;

                  if (esEdicion) {
                    await DatabaseHelper.instance.updateProducto(
                      Producto(
                        id: productoExistente.id,
                        nombre: nombre,
                        cantidad: cantidad,
                      ),
                      cantidadAnterior: productoExistente.cantidad,
                    );
                  } else {
                    await DatabaseHelper.instance.insertProducto(
                      Producto(nombre: nombre, cantidad: cantidad),
                    );
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _refreshInventario();
                  }
                },
                child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarProducto(Producto producto) async {
    if (producto.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar del inventario'),
        content: Text(
          '¿Seguro que deseas eliminar "${producto.nombre}" del inventario?',
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
      await DatabaseHelper.instance.deleteProducto(producto.id!);
      if (!mounted) return;
      _refreshInventario();
    }
  }

  int _prioridadOrden(Producto p) {
    final lower = p.nombre.trim().toLowerCase();
    if (lower == 'botellas') return 0;
    if (lower == 'jugos') return 1;
    if (lower == 'devoluciones') return 2;
    if (lower == 'botellas vendidas') return 3;
    return 4;
  }

  bool _permitePonerEnCeroRapido(Producto p) {
    final lower = p.nombre.trim().toLowerCase();
    return lower == 'jugos' ||
        lower == 'devoluciones' ||
        lower == 'botellas vendidas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario OSAN'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay productos registrados.'));
          }

          final productos = List<Producto>.from(snapshot.data!);
          productos.sort((a, b) {
            final pa = _prioridadOrden(a);
            final pb = _prioridadOrden(b);
            if (pa != pb) return pa.compareTo(pb);
            return a.nombre.compareTo(b.nombre);
          });

          int stockBotellas = 0;
          int stockJugos = 0;
          int stockDevoluciones = 0;
          int stockVendidas = 0;
          for (final p in productos) {
            final lower = p.nombre.trim().toLowerCase();
            if (lower == 'botellas') stockBotellas = p.cantidad;
            if (lower == 'jugos') stockJugos = p.cantidad;
            if (lower == 'devoluciones') stockDevoluciones = p.cantidad;
            if (lower == 'botellas vendidas') stockVendidas = p.cantidad;
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: productos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PanelCicloBotellas(
                  stockBotellas: stockBotellas,
                  stockJugos: stockJugos,
                  stockDevoluciones: stockDevoluciones,
                  stockVendidas: stockVendidas,
                  onHacerJugos: () => _mostrarModalHacerJugos(
                    stockBotellas: stockBotellas,
                    stockJugos: stockJugos,
                    stockVendidas: stockVendidas,
                  ),
                  onCargarDevoluciones: () => _mostrarModalCargarDevoluciones(
                    stockBotellas: stockBotellas,
                    stockDevoluciones: stockDevoluciones,
                    stockVendidas: stockVendidas,
                  ),
                  onCerrarTarde: _cerrarJornadaTarde,
                );
              }

              final item = productos[index - 1];
              return ProductoCard(
                producto: item,
                onDecrementar: () => _modificarCantidad(item, -1),
                onIncrementar: () => _modificarCantidad(item, 1),
                onEditar: () =>
                    _mostrarModalFormularioProducto(productoExistente: item),
                onEliminar: () => _confirmarEliminarProducto(item),
                onPonerEnCero: _permitePonerEnCeroRapido(item)
                    ? () => _ponerEnCeroIndividual(item)
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _mostrarModalFormularioProducto(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PanelCicloBotellas extends StatelessWidget {
  final int stockBotellas;
  final int stockJugos;
  final int stockDevoluciones;
  final int stockVendidas;
  final VoidCallback onHacerJugos;
  final VoidCallback onCargarDevoluciones;
  final VoidCallback onCerrarTarde;

  const _PanelCicloBotellas({
    required this.stockBotellas,
    required this.stockJugos,
    required this.stockDevoluciones,
    required this.stockVendidas,
    required this.onHacerJugos,
    required this.onCargarDevoluciones,
    required this.onCerrarTarde,
  });

  @override
  Widget build(BuildContext context) {
    final hayMovimientosDelDia = stockJugos > 0 || stockDevoluciones > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control Diario de Botellas y Devoluciones',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CajaMetricaEnvase(
                  titulo: 'Botellas en Casa',
                  subtitulo: 'Vacías disponibles',
                  cantidad: stockBotellas,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CajaMetricaEnvase(
                  titulo: 'Botellas Vendidas',
                  subtitulo: 'No regresaron',
                  cantidad: stockVendidas,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CajaMetricaEnvase(
                  titulo: 'Jugos del Día',
                  subtitulo: 'Poner en 0 en tarde',
                  cantidad: stockJugos,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CajaMetricaEnvase(
                  titulo: 'Devoluciones Hoy',
                  subtitulo: 'Poner en 0 en tarde',
                  cantidad: stockDevoluciones,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onHacerJugos,
                  icon: const Icon(Icons.local_drink, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '1. Hacer Jugos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onCargarDevoluciones,
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '2. Devoluciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hayMovimientosDelDia) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onCerrarTarde,
                icon: const Icon(Icons.wb_twilight, size: 18),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '3. Cerrar Tarde: Poner Jugos y Devoluciones en 0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CajaMetricaEnvase extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int cantidad;

  const _CajaMetricaEnvase({
    required this.titulo,
    required this.subtitulo,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              FormatoUtils.entero(cantidad),
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitulo,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
