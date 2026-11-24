import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/productos.dart';
import '../models/cliente.dart';
import '../models/entrega.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const List<String> nombresProductosFijos = [
    'Botellas',
    'Jugos',
    'Devoluciones',
    'Jugos vendidos',
    'Jugos despachados',
  ];

  static bool esProductoFijo(String nombre) {
    final lower = nombre.trim().toLowerCase();
    return nombresProductosFijos.any((n) => n.toLowerCase() == lower);
  }

  static bool esProductoHistorico(String nombre) {
    return false;
  }

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
      version: 7,
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
      ...nombresProductosFijos,
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
    if (oldVersion < 5) {
      await _migrarColumnaTipoEntregas(db);
    }
    if (oldVersion < 7) {
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
        tipo TEXT NOT NULL DEFAULT 'vendido',
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrarColumnaTipoEntregas(Database db) async {
    final columnas = await db.rawQuery('PRAGMA table_info(entregas)');
    final tieneTipo = columnas.any((col) => col['name'] == 'tipo');
    if (!tieneTipo) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN tipo TEXT NOT NULL DEFAULT 'vendido'",
      );
    }
  }

  Future<void> _asegurarItemsCicloBotellas(DatabaseExecutor db) async {
    // Si existía 'Botellas vendidas', renombrarlo a 'Jugos vendidos'
    final antiguo = await db.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: ['botellas vendidas'],
      limit: 1,
    );
    if (antiguo.isNotEmpty) {
      final nuevoExiste = await db.query(
        'productos',
        where: 'LOWER(nombre) = ?',
        whereArgs: ['jugos vendidos'],
        limit: 1,
      );
      if (nuevoExiste.isEmpty) {
        final sumaVentas = await db.rawQuery(
          "SELECT COALESCE(SUM(cantidad_botellas), 0) AS total FROM entregas WHERE tipo = 'vendido'",
        );
        final totalVendidos = (sumaVentas.first['total'] as num?)?.toInt() ?? 0;
        await db.update(
          'productos',
          {
            'nombre': 'Jugos vendidos',
            'cantidad': totalVendidos,
          },
          where: 'id = ?',
          whereArgs: [antiguo.first['id']],
        );
      } else {
        await db.delete(
          'productos',
          where: 'id = ?',
          whereArgs: [antiguo.first['id']],
        );
      }
    }

    // Si existía 'Jugos salidos', renombrarlo a 'Jugos despachados' y sincronizar con los jugos dejados a clientes
    final antiguoSalidos = await db.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: ['jugos salidos'],
      limit: 1,
    );
    if (antiguoSalidos.isNotEmpty) {
      final despachadosExiste = await db.query(
        'productos',
        where: 'LOWER(nombre) = ?',
        whereArgs: ['jugos despachados'],
        limit: 1,
      );
      if (despachadosExiste.isEmpty) {
        final sumaDejados = await db.rawQuery(
          "SELECT COALESCE(SUM(cantidad_botellas), 0) AS total FROM entregas WHERE tipo = 'dejado'",
        );
        final totalDejados = (sumaDejados.first['total'] as num?)?.toInt() ?? 0;
        await db.update(
          'productos',
          {
            'nombre': 'Jugos despachados',
            'cantidad': totalDejados,
          },
          where: 'id = ?',
          whereArgs: [antiguoSalidos.first['id']],
        );
      } else {
        await db.delete(
          'productos',
          where: 'id = ?',
          whereArgs: [antiguoSalidos.first['id']],
        );
      }
    }

    for (final nombre in nombresProductosFijos) {
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

  // Obtener todos los productos asegurando que existan los ítems fijos del ciclo
  Future<List<Producto>> getProductos() async {
    final db = await instance.database;
    await _asegurarItemsCicloBotellas(db);
    final result = await db.query('productos', orderBy: 'nombre ASC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  // Insertar un nuevo producto (evita duplicar los ítems fijos del sistema)
  Future<int> insertProducto(Producto producto) async {
    if (esProductoFijo(producto.nombre)) {
      return 0;
    }
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  // Actualizar un producto protegiendo nombres fijos, contador histórico y reglas del ciclo
  Future<int> updateProducto(
    Producto producto, {
    int? cantidadAnterior,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);

      int prev = cantidadAnterior ?? producto.cantidad;
      String nombreFinal = producto.nombre.trim();

      if (producto.id != null) {
        final actualRows = await txn.query(
          'productos',
          where: 'id = ?',
          whereArgs: [producto.id],
          limit: 1,
        );
        if (actualRows.isNotEmpty) {
          final nombreActual = (actualRows.first['nombre'] as String).trim();
          final cantidadDb = (actualRows.first['cantidad'] as num).toInt();
          if (cantidadAnterior == null) {
            prev = cantidadDb;
          }
          // Los productos fijos nunca pueden cambiar de nombre
          if (esProductoFijo(nombreActual)) {
            nombreFinal = nombreActual;
          }
          // El contador histórico de Jugos salidos nunca puede reducirse ni reiniciarse
          if (esProductoHistorico(nombreActual) &&
              producto.cantidad < cantidadDb) {
            return 0;
          }
        }
      }

      final nombreLower = nombreFinal.toLowerCase();
      final nuevaCantidad = producto.cantidad < 0 ? 0 : producto.cantidad;
      final delta = nuevaCantidad - prev;

      // Si aumentan los Jugos preparados (+delta):
      // - Se restan de Botellas disponibles (-delta)
      if (nombreLower == 'jugos' && delta > 0) {
        await _ajustarPorNombreEnTxn(txn, 'botellas', -delta);
      }
      // Si se cargan nuevas Devoluciones (+delta):
      // - Se suman a Botellas disponibles para reutilizar (+delta)
      else if (nombreLower == 'devoluciones' && delta > 0) {
        await _ajustarPorNombreEnTxn(txn, 'botellas', delta);
      }

      return await txn.update(
        'productos',
        {
          'nombre': nombreFinal,
          'cantidad': nuevaCantidad,
        },
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
  Future<void> producirJugos(int cantidad) async {
    if (cantidad <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      await _ajustarPorNombreEnTxn(txn, 'botellas', -cantidad);
      await _ajustarPorNombreEnTxn(txn, 'jugos', cantidad);
    });
  }

  /// Cargar Devoluciones (Mañana):
  /// - Suma `cantidad` a Devoluciones del día
  /// - Suma `cantidad` a Botellas disponibles (se reutilizan)
  Future<void> registrarDevoluciones(int cantidad) async {
    if (cantidad <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      await _ajustarPorNombreEnTxn(txn, 'devoluciones', cantidad);
      await _ajustarPorNombreEnTxn(txn, 'botellas', cantidad);
    });
  }

  /// Cerrar Tarde (Poner en 0 Jugos y Devoluciones del día):
  /// Limpia los contadores diarios de Jugos y Devoluciones a 0 para evitar confusión
  /// al día siguiente, conservando intactos Botellas, Botellas vendidas y Jugos salidos.
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

  /// Poner en 0 un contador permitido ('jugos', 'devoluciones', 'jugos despachados' o 'jugos vendidos')
  /// sin afectar el stock de Botellas.
  Future<void> ponerProductoEnCeroPorNombre(String nombre) async {
    final lower = nombre.trim().toLowerCase();
    if (lower != 'jugos' &&
        lower != 'devoluciones' &&
        lower != 'jugos despachados' &&
        lower != 'jugos vendidos') {
      return;
    }
    final db = await instance.database;
    await db.update(
      'productos',
      {'cantidad': 0},
      where: 'LOWER(nombre) = ?',
      whereArgs: [lower],
    );
  }

  /// Reiniciar a 0 el contador de Devoluciones sin afectar las Botellas ya sumadas.
  Future<void> reiniciarContadorDevoluciones() async {
    await ponerProductoEnCeroPorNombre('devoluciones');
  }

  // Eliminar un producto (bloqueado para los ítems fijos del sistema)
  Future<int> deleteProducto(int id) async {
    final db = await instance.database;
    final rows = await db.query(
      'productos',
      columns: ['nombre'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final nombre = (rows.first['nombre'] ?? '') as String;
      if (esProductoFijo(nombre)) {
        return 0;
      }
    }
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
      await _asegurarItemsCicloBotellas(txn);
      final totalesCliente = await txn.rawQuery(
        '''
        SELECT
          COALESCE(SUM(CASE WHEN tipo = 'vendido' THEN cantidad_botellas ELSE 0 END), 0) AS total_vendidos,
          COALESCE(SUM(CASE WHEN tipo = 'dejado' THEN cantidad_botellas ELSE 0 END), 0) AS total_dejados
        FROM entregas
        WHERE cliente_id = ?
        ''',
        [id],
      );
      final totalVendidosCliente =
          (totalesCliente.first['total_vendidos'] as num?)?.toInt() ?? 0;
      final totalDejadosCliente =
          (totalesCliente.first['total_dejados'] as num?)?.toInt() ?? 0;
      if (totalVendidosCliente > 0) {
        await _ajustarPorNombreEnTxn(
          txn,
          'jugos vendidos',
          -totalVendidosCliente,
        );
      }
      if (totalDejadosCliente > 0) {
        await _ajustarPorNombreEnTxn(
          txn,
          'jugos despachados',
          -totalDejadosCliente,
        );
      }

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

  // Registrar una entrega de botellas a un cliente (dejado o vendido):
  // - Si es "dejado", se suma automáticamente a "Jugos despachados" en el inventario.
  // - Si es "vendido", se suma automáticamente a "Jugos vendidos" en el inventario.
  Future<int> insertEntrega(
    Entrega entrega, {
    bool descontarDeInventario = false,
  }) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      final id = await txn.insert('entregas', entrega.toMap());
      if (entrega.cantidadBotellas > 0) {
        if (entrega.tipo == TipoEntrega.vendido) {
          await _ajustarPorNombreEnTxn(
            txn,
            'jugos vendidos',
            entrega.cantidadBotellas,
          );
        } else if (entrega.tipo == TipoEntrega.dejado) {
          await _ajustarPorNombreEnTxn(
            txn,
            'jugos despachados',
            entrega.cantidadBotellas,
          );
        }
      }
      return id;
    });
  }

  // Actualizar una entrega existente y ajustar "Jugos vendidos" o "Jugos despachados"
  Future<int> updateEntrega(Entrega entrega) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      if (entrega.id != null) {
        final prevRows = await txn.query(
          'entregas',
          columns: ['cantidad_botellas', 'tipo'],
          where: 'id = ?',
          whereArgs: [entrega.id],
          limit: 1,
        );
        if (prevRows.isNotEmpty) {
          final prevCant =
              (prevRows.first['cantidad_botellas'] as num).toInt();
          final prevTipo =
              TipoEntrega.fromDb(prevRows.first['tipo'] as String?);

          final prevVendidos = prevTipo == TipoEntrega.vendido ? prevCant : 0;
          final nuevoVendidos = entrega.tipo == TipoEntrega.vendido
              ? entrega.cantidadBotellas
              : 0;
          final deltaVendidos = nuevoVendidos - prevVendidos;
          if (deltaVendidos != 0) {
            await _ajustarPorNombreEnTxn(txn, 'jugos vendidos', deltaVendidos);
          }

          final prevDejados = prevTipo == TipoEntrega.dejado ? prevCant : 0;
          final nuevoDejados = entrega.tipo == TipoEntrega.dejado
              ? entrega.cantidadBotellas
              : 0;
          final deltaDejados = nuevoDejados - prevDejados;
          if (deltaDejados != 0) {
            await _ajustarPorNombreEnTxn(
              txn,
              'jugos despachados',
              deltaDejados,
            );
          }
        }
      }

      return await txn.update(
        'entregas',
        entrega.toMap(),
        where: 'id = ?',
        whereArgs: [entrega.id],
      );
    });
  }

  // Eliminar una entrega y descontar de "Jugos vendidos" o "Jugos despachados"
  Future<int> deleteEntrega(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await _asegurarItemsCicloBotellas(txn);
      final prevRows = await txn.query(
        'entregas',
        columns: ['cantidad_botellas', 'tipo'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (prevRows.isNotEmpty) {
        final prevCant = (prevRows.first['cantidad_botellas'] as num).toInt();
        final prevTipo = TipoEntrega.fromDb(prevRows.first['tipo'] as String?);
        if (prevCant > 0) {
          if (prevTipo == TipoEntrega.vendido) {
            await _ajustarPorNombreEnTxn(txn, 'jugos vendidos', -prevCant);
          } else if (prevTipo == TipoEntrega.dejado) {
            await _ajustarPorNombreEnTxn(txn, 'jugos despachados', -prevCant);
          }
        }
      }

      return await txn.delete(
        'entregas',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Obtener las entregas de un cliente dentro de un rango de fechas (opcionalmente filtradas por tipo)
  Future<List<Entrega>> getEntregasPorClienteYRango(
    int clienteId,
    String fechaInicio,
    String fechaFin, {
    TipoEntrega? tipo,
  }) async {
    final db = await instance.database;
    final where = tipo == null
        ? 'cliente_id = ? AND fecha >= ? AND fecha <= ?'
        : 'cliente_id = ? AND fecha >= ? AND fecha <= ? AND tipo = ?';
    final whereArgs = tipo == null
        ? [clienteId, fechaInicio, fechaFin]
        : [clienteId, fechaInicio, fechaFin, tipo.valorDb];
    final result = await db.query(
      'entregas',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC, id DESC',
    );
    return result.map((json) => Entrega.fromMap(json)).toList();
  }

  // Obtener el último precio registrado en ventas para sugerirlo automáticamente
  Future<double?> getUltimoPrecioSugerido(int clienteId) async {
    final db = await instance.database;
    final delCliente = await db.query(
      'entregas',
      columns: ['precio_unitario'],
      where: "cliente_id = ? AND tipo = 'vendido' AND precio_unitario > 0",
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
      where: "tipo = 'vendido' AND precio_unitario > 0",
      orderBy: 'id DESC',
      limit: 1,
    );
    if (general.isNotEmpty) {
      return (general.first['precio_unitario'] as num).toDouble();
    }
    return null;
  }

  // Resumen completo (Hoy, Semana y Mes) para todos los clientes separando dejados y vendidos
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
        COALESCE(SUM(CASE WHEN tipo = 'dejado' AND fecha = ? THEN cantidad_botellas ELSE 0 END), 0) AS dejados_hoy,
        COALESCE(SUM(CASE WHEN tipo = 'dejado' AND fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS dejados_semana,
        COALESCE(SUM(CASE WHEN tipo = 'dejado' AND fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS dejados_mes,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha = ? THEN cantidad_botellas ELSE 0 END), 0) AS vendidos_hoy,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha = ? THEN total ELSE 0.0 END), 0.0) AS total_hoy,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS vendidos_semana,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha >= ? AND fecha <= ? THEN total ELSE 0.0 END), 0.0) AS total_semana,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha >= ? AND fecha <= ? THEN cantidad_botellas ELSE 0 END), 0) AS vendidos_mes,
        COALESCE(SUM(CASE WHEN tipo = 'vendido' AND fecha >= ? AND fecha <= ? THEN total ELSE 0.0 END), 0.0) AS total_mes
      FROM entregas
      WHERE fecha >= ? AND fecha <= ?
      GROUP BY cliente_id
      ''',
      [
        fechaHoy,
        fechaInicio,
        fechaFin,
        inicioMes,
        finMes,
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
        botellasDejadasHoy: (row['dejados_hoy'] as num).toInt(),
        botellasDejadasSemana: (row['dejados_semana'] as num).toInt(),
        botellasDejadasMes: (row['dejados_mes'] as num).toInt(),
        botellasVendidasHoy: (row['vendidos_hoy'] as num).toInt(),
        totalHoy: (row['total_hoy'] as num).toDouble(),
        botellasVendidasSemana: (row['vendidos_semana'] as num).toInt(),
        totalSemana: (row['total_semana'] as num).toDouble(),
        botellasVendidasMes: (row['vendidos_mes'] as num).toInt(),
        totalMes: (row['total_mes'] as num).toDouble(),
      );
    }
    return mapa;
  }

  // Obtener reporte mensual desglosado por cada cliente (ingresos calculados con jugos vendidos)
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
        COALESCE(SUM(CASE WHEN e.tipo = 'dejado' THEN e.cantidad_botellas ELSE 0 END), 0) AS dejados_mes,
        COALESCE(SUM(CASE WHEN e.tipo = 'vendido' THEN e.cantidad_botellas ELSE 0 END), 0) AS vendidos_mes,
        COALESCE(SUM(CASE WHEN e.tipo = 'vendido' THEN e.total ELSE 0.0 END), 0.0) AS total_mes
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
            botellasDejadasMes: (row['dejados_mes'] as num).toInt(),
            botellasVendidasMes: (row['vendidos_mes'] as num).toInt(),
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
