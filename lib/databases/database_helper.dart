import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/productos.dart';
import '../models/cliente.dart';
import '../models/entrega.dart';

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
    final path = kIsWeb
        ? filePath
        : join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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

    // Tabla de Entregas diarias de botellas de jugo por cliente
    await _crearTablaEntregas(db);

    // Productos iniciales del inventario
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

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _crearTablaEntregas(db);
    }
  }

  Future<void> _crearTablaEntregas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entregas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        cantidad_botellas INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // CRUD PRODUCTOS (INVENTARIO)
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

  // Descontar o devolver stock al producto "Botellas" si existe
  Future<void> ajustarStockBotellas(int delta) async {
    final db = await instance.database;
    final res = await db.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: ['botellas'],
      limit: 1,
    );
    if (res.isNotEmpty) {
      final producto = Producto.fromMap(res.first);
      final nuevaCantidad = (producto.cantidad + delta) < 0
          ? 0
          : (producto.cantidad + delta);
      await db.update(
        'productos',
        {'cantidad': nuevaCantidad},
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    }
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

  // Eliminar un cliente y sus entregas asociadas
  Future<int> deleteCliente(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'entregas',
        where: 'cliente_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ==========================================
  // CRUD ENTREGAS DIARIAS Y RESUMEN SEMANAL
  // ==========================================

  // Registrar una entrega de botellas a un cliente
  Future<int> insertEntrega(
    Entrega entrega, {
    bool descontarDeInventario = false,
  }) async {
    final db = await instance.database;
    final id = await db.insert('entregas', entrega.toMap());
    if (descontarDeInventario && entrega.cantidadBotellas > 0) {
      await ajustarStockBotellas(-entrega.cantidadBotellas);
    }
    return id;
  }

  // Actualizar una entrega existente
  Future<int> updateEntrega(Entrega entrega) async {
    final db = await instance.database;
    return await db.update(
      'entregas',
      entrega.toMap(),
      where: 'id = ?',
      whereArgs: [entrega.id],
    );
  }

  // Eliminar una entrega
  Future<int> deleteEntrega(int id) async {
    final db = await instance.database;
    return await db.delete(
      'entregas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener las entregas de un cliente dentro de un rango de fechas (semana)
  Future<List<Entrega>> getEntregasPorClienteYRango(
    int clienteId,
    String fechaInicio,
    String fechaFin,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'entregas',
      where: 'cliente_id = ? AND fecha >= ? AND fecha <= ?',
      whereArgs: [clienteId, fechaInicio, fechaFin],
      orderBy: 'fecha DESC, id DESC',
    );
    return result.map((json) => Entrega.fromMap(json)).toList();
  }

  // Obtener el último precio registrado para sugerirlo automáticamente
  Future<double?> getUltimoPrecioSugerido(int clienteId) async {
    final db = await instance.database;
    final delCliente = await db.query(
      'entregas',
      columns: ['precio_unitario'],
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (delCliente.isNotEmpty) {
      return (delCliente.first['precio_unitario'] as num).toDouble();
    }
    final general = await db.query(
      'entregas',
      columns: ['precio_unitario'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (general.isNotEmpty) {
      return (general.first['precio_unitario'] as num).toDouble();
    }
    return null;
  }

  // Resumen semanal (botellas hoy, botellas en la semana y total $) para todos los clientes
  Future<Map<int, ResumenClienteSemana>> getResumenesSemanales({
    required String fechaInicio,
    required String fechaFin,
    required String fechaHoy,
  }) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        cliente_id,
        COALESCE(SUM(cantidad_botellas), 0) AS botellas_semana,
        COALESCE(SUM(total), 0.0) AS total_semana,
        COALESCE(SUM(CASE WHEN fecha = ? THEN cantidad_botellas ELSE 0 END), 0) AS botellas_hoy
      FROM entregas
      WHERE fecha >= ? AND fecha <= ?
      GROUP BY cliente_id
      ''',
      [fechaHoy, fechaInicio, fechaFin],
    );

    final Map<int, ResumenClienteSemana> mapa = {};
    for (final row in rows) {
      final clienteId = row['cliente_id'] as int;
      mapa[clienteId] = ResumenClienteSemana(
        botellasHoy: (row['botellas_hoy'] as num).toInt(),
        botellasSemana: (row['botellas_semana'] as num).toInt(),
        totalSemana: (row['total_semana'] as num).toDouble(),
      );
    }
    return mapa;
  }

  // Cerrar la base de datos cuando no se use
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
