import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/productos.dart';

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

  void _modificarCantidad(Producto producto, int cambio) async {
    final nuevaCantidad = producto.cantidad + cambio;
    if (nuevaCantidad < 0) return; // No permitir cantidades negativas

    final actualizado = Producto(
      id: producto.id,
      nombre: producto.nombre,
      cantidad: nuevaCantidad,
    );

    await DatabaseHelper.instance.updateProducto(actualizado);
    _refreshInventario();
  }

  void _mostrarModalAgregarProducto() {
    final controllerNombre = TextEditingController();
    final controllerCantidad = TextEditingController();

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
            const Text(
              'Agregar Nuevo Producto / Insumo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controllerNombre,
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
                labelText: 'Cantidad inicial',
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
                final cantidad = int.tryParse(controllerCantidad.text) ?? 0;

                if (nombre.isNotEmpty) {
                  await DatabaseHelper.instance.insertProducto(
                    Producto(nombre: nombre, cantidad: cantidad),
                  );
                  Navigator.pop(ctx);
                  _refreshInventario();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
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
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final item = productos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    item.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Stock: ${item.cantidad}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _modificarCantidad(item, -1),
                      ),
                      Text(
                        '${item.cantidad}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => _modificarCantidad(item, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _mostrarModalAgregarProducto,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}