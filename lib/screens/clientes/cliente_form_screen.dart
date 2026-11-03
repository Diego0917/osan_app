import 'package:flutter/material.dart';
import '../../databases/database_helper.dart';
import '../../models/cliente.dart';

Future<bool> mostrarFormularioCliente(
  BuildContext context, {
  Cliente? clienteExistente,
}) async {
  final esEdicion = clienteExistente != null;
  final controllerNombre = TextEditingController(
    text: clienteExistente?.nombre ?? '',
  );
  final controllerTelefono = TextEditingController(
    text: clienteExistente?.telefono ?? '',
  );
  final controllerDireccion = TextEditingController(
    text: clienteExistente?.direccion ?? '',
  );
  String? mensajeError;

  final resultado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                esEdicion ? 'Editar Cliente' : 'Registrar Nuevo Cliente',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controllerNombre,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre completo *',
                  errorText: mensajeError,
                  border: const OutlineInputBorder(),
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
                textCapitalization: TextCapitalization.sentences,
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

                  if (nombre.isEmpty) {
                    setModalState(() {
                      mensajeError = 'Ingresa el nombre del cliente';
                    });
                    return;
                  }

                  if (esEdicion) {
                    await DatabaseHelper.instance.updateCliente(
                      Cliente(
                        id: clienteExistente.id,
                        nombre: nombre,
                        telefono: telefono,
                        direccion: direccion,
                      ),
                    );
                  } else {
                    await DatabaseHelper.instance.insertCliente(
                      Cliente(
                        nombre: nombre,
                        telefono: telefono,
                        direccion: direccion,
                      ),
                    );
                  }

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(esEdicion ? 'Actualizar Cliente' : 'Guardar Cliente'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return resultado == true;
}
