class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String direccion;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: (map['nombre'] ?? '') as String,
      telefono: (map['telefono'] ?? '') as String,
      direccion: (map['direccion'] ?? '') as String,
    );
  }
}
