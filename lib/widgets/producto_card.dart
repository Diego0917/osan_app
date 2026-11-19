import 'package:flutter/material.dart';
import '../models/entrega.dart';
import '../models/productos.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onPonerEnCero;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEditar,
    required this.onEliminar,
    this.onPonerEnCero,
  });

  String? _notaCiclo(String nombre) {
    final lower = nombre.trim().toLowerCase();
    if (lower == 'botellas') {
      return 'Envases vacíos en casa (recibe las devoluciones)';
    } else if (lower == 'jugos') {
      return 'Producción del día (resta de Botellas • poner en 0 en la tarde)';
    } else if (lower == 'devoluciones') {
      return 'Recogidas en la mañana (suma a Botellas • poner en 0 en la tarde)';
    } else if (lower == 'botellas vendidas') {
      return 'Botellas que no regresaron (Jugos salidos - Devoluciones)';
    }
    return null;
  }

  IconData _iconoProducto(String nombre) {
    final lower = nombre.trim().toLowerCase();
    if (lower == 'botellas') return Icons.liquor;
    if (lower == 'jugos') return Icons.local_drink;
    if (lower == 'devoluciones') return Icons.autorenew;
    if (lower == 'botellas vendidas') return Icons.sell;
    return Icons.inventory_2;
  }

  @override
  Widget build(BuildContext context) {
    final cantidadTexto = FormatoUtils.entero(producto.cantidad);
    final nota = _notaCiclo(producto.nombre);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      _iconoProducto(producto.nombre),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (nota != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            nota,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (valor) {
                      if (valor == 'editar') {
                        onEditar();
                      } else if (valor == 'cero' && onPonerEnCero != null) {
                        onPonerEnCero!();
                      } else if (valor == 'eliminar') {
                        onEliminar();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      if (onPonerEnCero != null && producto.cantidad > 0)
                        const PopupMenuItem(
                          value: 'cero',
                          child: Row(
                            children: [
                              Icon(
                                Icons.restart_alt,
                                size: 20,
                                color: Colors.deepOrange,
                              ),
                              SizedBox(width: 8),
                              Text('Poner en 0 (Tarde)'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Stock:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            cantidadTexto,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onPonerEnCero != null && producto.cantidad > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.deepOrange,
                          ),
                          onPressed: onPonerEnCero,
                          child: const Text(
                            'Poner en 0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Disminuir',
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 26,
                      ),
                      onPressed: onDecrementar,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Aumentar',
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                        size: 26,
                      ),
                      onPressed: onIncrementar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
