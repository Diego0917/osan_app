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
      'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      cantidad: map['cantidad'],
    );
  }
}