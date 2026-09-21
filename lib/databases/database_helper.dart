import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/productos.dart';
import '../models/cliente.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('osan_juice.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Creación de las tablas de la base de datos
  Future _createDB(Database db, int version) async {
    // Tabla de Productos / Inventario
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL
      )
    ''');

    // Tabla de Clientes
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT
      )
    ''');
    //Primero productos
    final productosIniciales = [
      'Botellas',
      'Canastas de mandarina',
      'Bolsas',
      'Guantes',
      'Naranja',
    ];

    for (var nombre in productosIniciales) {
      await db.insert('productos', {
        'nombre': nombre,
        'cantidad': 0,
      });
    }
  }

  // ==========================================
  // CRUD PRODUCTOS
  // ==========================================

  // Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    final db = await instance.database;
    final result = await db.query('productos', orderBy: 'nombre ASC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  // Insertar un nuevo producto
  Future<int> insertProducto(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  // Actualizar un producto (por ejemplo, stock o nombre)
  Future<int> updateProducto(Producto producto) async {
    final db = await instance.database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  // Eliminar un producto
  Future<int> deleteProducto(int id) async {
    final db = await instance.database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // CRUD CLIENTES
  // ==========================================

  // Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    final db = await instance.database;
    final result = await db.query('clientes', orderBy: 'nombre ASC');
    return result.map((json) => Cliente.fromMap(json)).toList();
  }

  // Insertar un nuevo cliente
  Future<int> insertCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  // Actualizar datos de un cliente
  Future<int> updateCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  // Eliminar un cliente
  Future<int> deleteCliente(int id) async {
    final db = await instance.database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cerrar la base de datos cuando no se use
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}