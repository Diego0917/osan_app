import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Cliente>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    _refreshClientes();
  }

  void _refreshClientes() {
    setState(() {
      _clientesFuture = DatabaseHelper.instance.getClientes();
    });
  }

  void _mostrarModalAgregarCliente() {
    final controllerNombre = TextEditingController();
    final controllerTelefono = TextEditingController();
    final controllerDireccion = TextEditingController();

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
              'Registrar Nuevo Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controllerNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controllerTelefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controllerDireccion,
              decoration: const InputDecoration(
                labelText: 'Dirección / Ubicación',
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
                final telefono = controllerTelefono.text.trim();
                final direccion = controllerDireccion.text.trim();

                if (nombre.isNotEmpty) {
                  await DatabaseHelper.instance.insertCliente(
                    Cliente(
                      nombre: nombre,
                      telefono: telefono,
                      direccion: direccion,
                    ),
                  );
                  Navigator.pop(ctx);
                  _refreshClientes();
                }
              },
              child: const Text('Guardar Cliente'),
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
        title: const Text('Gestión de Clientes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay clientes registrados.'));
          }

          final clientes = snapshot.data!;
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    cliente.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Tel: ${cliente.telefono}\nUbicación: ${cliente.direccion}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      if (cliente.id != null) {
                        await DatabaseHelper.instance.deleteCliente(cliente.id!);
                        _refreshClientes();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _mostrarModalAgregarCliente,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}