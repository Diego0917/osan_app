class Producto {
  final int? id;
  final String nombre; // Ejemplo: "Botellas", "Naranja", "Guantes"
  final int cantidad;

  Producto({
    this.id,
    required this.nombre,
    required this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: (map['nombre'] ?? '') as String,
      cantidad: (map['cantidad'] ?? 0) as int,
    );
  }
}
