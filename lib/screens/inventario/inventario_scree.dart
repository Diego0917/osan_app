import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
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
    if (nuevaCantidad < 0) return; // No permitir cantidades negativas

    final actualizado = Producto(
      id: producto.id,
      nombre: producto.nombre,
      cantidad: nuevaCantidad,
    );

    await DatabaseHelper.instance.updateProducto(actualizado);
    if (!mounted) return;
    _refreshInventario();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              esEdicion
                  ? 'Editar Producto / Insumo'
                  : 'Agregar Nuevo Producto / Insumo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                final cantidadParsed = int.tryParse(controllerCantidad.text) ?? 0;
                final cantidad = cantidadParsed < 0 ? 0 : cantidadParsed;

                if (nombre.isEmpty) return;

                if (esEdicion) {
                  await DatabaseHelper.instance.updateProducto(
                    Producto(
                      id: productoExistente.id,
                      nombre: nombre,
                      cantidad: cantidad,
                    ),
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

          final productos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 6, bottom: 80),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final item = productos[index];
              return ProductoCard(
                producto: item,
                onDecrementar: () => _modificarCantidad(item, -1),
                onIncrementar: () => _modificarCantidad(item, 1),
                onEditar: () =>
                    _mostrarModalFormularioProducto(productoExistente: item),
                onEliminar: () => _confirmarEliminarProducto(item),
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
