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
      version: 4,
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

    // Productos iniciales del inventario (incluyendo el ciclo completo de botellas)
    final productosIniciales = [
      'Botellas',
      'Jugos',
      'Devoluciones',
      'Botellas vendidas',
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
    if (oldVersion < 4) {
      await _asegurarItemsCicloBotellas(db);
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

  Future<void> _asegurarItemsCicloBotellas(DatabaseExecutor db) async {
    const itemsCiclo = [
      'Botellas',
      'Jugos',
      'Devoluciones',
      'Botellas vendidas',
    ];
    for (final nombre in itemsCiclo) {
      final existente = await db.query(
        'productos',
        where: 'LOWER(nombre) = ?',
        whereArgs: [nombre.toLowerCase()],
        limit: 1,
      );
      if (existente.isEmpty) {
        await db.insert('productos', {
          'nombre': nombre,
          'cantidad': 0,
        });
      }
    }
  }

  // ==========================================
  // CRUD PRODUCTOS (INVENTARIO) Y CICLO DE BOTELLAS
  // ==========================================

  // Obtener todos los productos asegurando que existan Botellas, Jugos, Devoluciones y Botellas vendidas
  Future<List<Producto>> getProductos() async {
    final db = await instance.database;
    await _asegurarItemsCicloBotellas(db);
    final result = await db.query('productos', orderBy: 'nombre ASC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  // Insertar un nuevo producto
  Future<int> insertProducto(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  // Actualizar un producto aplicando reglas del ciclo si es Jugos o Devoluciones
  Future<int> updateProducto(
    Producto producto, {
    int? cantidadAnterior,
  }) async {
    final db = await instance.database;
    final nombreLower = producto.nombre.trim().toLowerCase();

    return await db.transaction((txn) async {
      int prev = cantidadAnterior ?? producto.cantidad;
      if (cantidadAnterior == null && producto.id != null) {
        final actualRows = await txn.query(
          'productos',
          where: 'id = ?',
          whereArgs: [producto.id],
          limit: 1,
        );
        if (actualRows.isNotEmpty) {
          prev = (actualRows.first['cantidad'] as num).toInt();
        }
      }

      final delta = producto.cantidad - prev;

      // Si aumentan los Jugos preparados (+delta):
      // - Se restan de Botellas disponibles (-delta)
      // - Salen como Botellas vendidas (+delta) hasta que regresen como devolución
      if (nombreLower == 'jugos' && delta > 0) {
        await _ajustarPorNombreEnTxn(txn, 'botellas', -delta);
        await _ajustarPorNombreEnTxn(txn, 'botellas vendidas', delta);
      }
      // Si se cargan nuevas Devoluciones (+delta):
      // - Se suman a Botellas disponibles para reutilizar (+delta)
      // - Se descuentan de Botellas vendidas porque sí regresaron (-delta)
      else if (nombreLower == 'devoluciones' && delta > 0) {
        await _ajustarPorNombreEnTxn(txn, 'botellas', delta);
        await _ajustarPorNombreEnTxn(txn, 'botellas vendidas', -delta);
      }

      return await txn.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    });
  }

  Future<void> _ajustarPorNombreEnTxn(
    DatabaseExecutor txn,
    String nombreLower,
    int delta,
  ) async {
    final rows = await txn.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: [nombreLower],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final prod = Producto.fromMap(rows.first);
      final nueva = (prod.cantidad + delta) < 0 ? 0 : (prod.cantidad + delta);
      await txn.update(
        'productos',
        {'cantidad': nueva},
        where: 'id = ?',
        whereArgs: [prod.id],
      );
    }
  }

  /// Hacer Jugos (Noche/Mañana):
  /// - Resta `cantidad` de Botellas disponibles
  /// - Suma `cantidad` a Jugos del día
  /// - Suma `cantidad` a Botellas vendidas (las que regresen luego como devolución se restarán de vendidas)
  Future<void> producirJugos(int cantidad) async {
    if (cantidad <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      await _ajustarPorNombreEnTxn(txn, 'botellas', -cantidad);
      await _ajustarPorNombreEnTxn(txn, 'jugos', cantidad);
      await _ajustarPorNombreEnTxn(txn, 'botellas vendidas', cantidad);
    });
  }

  /// Cargar Devoluciones (Mañana):
  /// - Suma `cantidad` a Devoluciones del día
  /// - Suma `cantidad` a Botellas disponibles (se reutilizan)
  /// - Resta `cantidad` de Botellas vendidas (porque esas botellas sí regresaron)
  Future<void> registrarDevoluciones(int cantidad) async {
    if (cantidad <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      await _ajustarPorNombreEnTxn(txn, 'devoluciones', cantidad);
      await _ajustarPorNombreEnTxn(txn, 'botellas', cantidad);
      await _ajustarPorNombreEnTxn(txn, 'botellas vendidas', -cantidad);
    });
  }

  /// Cerrar Tarde (Poner en 0 Jugos y Devoluciones del día):
  /// Limpia los contadores diarios de Jugos y Devoluciones a 0 para evitar confusión
  /// al día siguiente, conservando intactos Botellas disponibles y Botellas vendidas.
  Future<void> cerrarJornadaTarde() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'productos',
        {'cantidad': 0},
        where: 'LOWER(nombre) IN (?, ?)',
        whereArgs: ['jugos', 'devoluciones'],
      );
    });
  }

  /// Poner en 0 un producto específico por nombre (ej. 'jugos' o 'devoluciones')
  /// sin afectar el stock de Botellas.
  Future<void> ponerProductoEnCeroPorNombre(String nombre) async {
    final db = await instance.database;
    await db.update(
      'productos',
      {'cantidad': 0},
      where: 'LOWER(nombre) = ?',
      whereArgs: [nombre.trim().toLowerCase()],
    );
  }

  /// Reiniciar a 0 el contador de Devoluciones sin afectar las Botellas ya sumadas.
  Future<void> reiniciarContadorDevoluciones() async {
    await ponerProductoEnCeroPorNombre('devoluciones');
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

  // Descontar jugos entregados a un cliente únicamente del contador de "Jugos" del día
  // (nunca de "Botellas", ya que "Botellas" ya se descontó al hacer los jugos).
  Future<void> descontarEnvasesPorEntrega(int cantidadEntregada) async {
    if (cantidadEntregada <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      await _ajustarPorNombreEnTxn(txn, 'jugos', -cantidadEntregada);
    });
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
  // CRUD ENTREGAS DIARIAS, SEMANALES Y MENSUALES
  // ==========================================

  // Registrar una entrega de botellas a un cliente
  Future<int> insertEntrega(
    Entrega entrega, {
    bool descontarDeInventario = false,
  }) async {
    final db = await instance.database;
    final id = await db.insert('entregas', entrega.toMap());
    if (descontarDeInventario && entrega.cantidadBotellas > 0) {
      await descontarEnvasesPorEntrega(entrega.cantidadBotellas);
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

  // Obtener las entregas de un cliente dentro de un rango de fechas
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

  // Resumen completo (Hoy, Semana y Mes) para todos los clientes
  Future<Map<int, ResumenClienteSemana>> getResumenesSemanales({
    required String fechaInicio,
    required String fechaFin,
    required String fechaHoy,
    String? fechaInicioMes,
    String? fechaFinMes,
  }) async {
    final db = await instance.database;
    final fechaBase = FechaSemanaUtils.desdeIso(fechaHoy);
    final inicioMes =
        fechaInicioMes ??
        FechaSemanaUtils.aIso(FechaSemanaUtils.obtenerInicioMes(fechaBase));
    final finMes =
        fechaFinMes ??
        FechaSemanaUtils.aIso(FechaSemanaUtils.obtenerFinMes(fechaBase));

    final minFecha =
        fechaInicio.compareTo(inicioMes) < 0 ? fechaInicio : inicioMes;
    final maxFecha = fechaFin.compareTo(finMes) > 0 ? fechaFin : finMes;

    final rows = await db.rawQuery(
      '''
      SELECT
        cliente_id,
        COALESCE(SUM(CASE WHEN fecha = ? THEN cantidad_botellas ELSE 0 END), 0) AS botellas_hoy,
        COALESCE(SUM(CASE WHEN fecha = ? THEN total ELSE 0.0 END), 0.0) AS total_hoy,
        COALESCE(SUM(CASE WHEN fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS botellas_semana,
        COALESCE(SUM(CASE WHEN fecha >= ? AND fecha <= ? THEN total ELSE 0.0 END), 0.0) AS total_semana,
        COALESCE(SUM(CASE WHEN fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS botellas_mes,
        COALESCE(SUM(CASE WHEN fecha >= ? AND fecha <= ? THEN total ELSE 0.0 END), 0.0) AS total_mes
      FROM entregas
      WHERE fecha >= ? AND fecha <= ?
      GROUP BY cliente_id
      ''',
      [
        fechaHoy,
        fechaHoy,
        fechaInicio,
        fechaFin,
        fechaInicio,
        fechaFin,
        inicioMes,
        finMes,
        inicioMes,
        finMes,
        minFecha,
        maxFecha,
      ],
    );

    final Map<int, ResumenClienteSemana> mapa = {};
    for (final row in rows) {
      final clienteId = row['cliente_id'] as int;
      mapa[clienteId] = ResumenClienteSemana(
        botellasHoy: (row['botellas_hoy'] as num).toInt(),
        totalHoy: (row['total_hoy'] as num).toDouble(),
        botellasSemana: (row['botellas_semana'] as num).toInt(),
        totalSemana: (row['total_semana'] as num).toDouble(),
        botellasMes: (row['botellas_mes'] as num).toInt(),
        totalMes: (row['total_mes'] as num).toDouble(),
      );
    }
    return mapa;
  }

  // Obtener reporte mensual desglosado por cada cliente
  Future<List<ReporteClienteMes>> getReporteMensualPorClientes(
    String inicioMes,
    String finMes,
  ) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id AS cliente_id,
        c.nombre AS nombre,
        COALESCE(c.telefono, '') AS telefono,
        COALESCE(SUM(e.cantidad_botellas), 0) AS botellas_mes,
        COALESCE(SUM(e.total), 0.0) AS total_mes
      FROM clientes c
      LEFT JOIN entregas e
        ON e.cliente_id = c.id
        AND e.fecha >= ?
        AND e.fecha <= ?
      GROUP BY c.id, c.nombre, c.telefono
      ORDER BY total_mes DESC, c.nombre ASC
      ''',
      [inicioMes, finMes],
    );

    return rows
        .map(
          (row) => ReporteClienteMes(
            clienteId: row['cliente_id'] as int,
            nombreCliente: (row['nombre'] ?? '') as String,
            telefono: (row['telefono'] ?? '') as String,
            botellasMes: (row['botellas_mes'] as num).toInt(),
            totalMes: (row['total_mes'] as num).toDouble(),
          ),
        )
        .toList();
  }

  // Cerrar la base de datos cuando no se use
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
