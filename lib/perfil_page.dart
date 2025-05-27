import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? _perfil;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _error = 'No hay token de sesión';
          _cargando = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/usuarios/perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _perfil = jsonDecode(response.body);
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'No se pudo obtener el perfil';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de usuario'),
        backgroundColor: Colors.pink[100],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(fontSize: 22)))
              : _perfil == null
                  ? const Center(child: Text('No se encontró información de perfil', style: TextStyle(fontSize: 22)))
                  : Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.account_circle, size: 120, color: Colors.pink),
                                  const SizedBox(height: 24),
                                  Text(
                                    '${_perfil?["nombre"] ?? ""} ${_perfil?["apellido"] ?? ""}',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Correo: ${_perfil?["correo"] ?? ""}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Teléfono: ${_perfil?["telefono"] ?? ""}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fecha de nacimiento: ${_perfil?["fechaNacimiento"] ?? ""}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dirección: ${_perfil?["direccion"] ?? ""}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final resultado = await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) => _EditarPerfilDialog(perfil: _perfil!),
                                      );
                                      if (resultado != null) {
                                        await _modificarPerfil(resultado);
                                      }
                                    },
                                    child: const Text('Modificar perfil'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Future<void> _modificarPerfil(Map<String, dynamic> datos) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _error = 'No hay token de sesión';
          _cargando = false;
        });
        return;
      }
      // Elimina campos nulos o vacíos (por ejemplo, contraseña si no se cambia)
      datos.removeWhere((key, value) => value == null || value == '');
      final response = await http.put(
        Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/usuarios/modificar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datos),
      );
      if (response.statusCode == 200) {
        await _cargarPerfil();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado')),
          );
        }
      } else {
        setState(() {
          _error = 'No se pudo modificar el perfil';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _cargando = false;
      });
    }
  }
}

class _EditarPerfilDialog extends StatefulWidget {
  final Map<String, dynamic> perfil;
  const _EditarPerfilDialog({required this.perfil});

  @override
  State<_EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<_EditarPerfilDialog> {
  late TextEditingController _nombre;
  late TextEditingController _apellido;
  late TextEditingController _telefono;
  late TextEditingController _correo;
  late TextEditingController _contrasena;
  late TextEditingController _direccion;
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.perfil['nombre'] ?? '');
    _apellido = TextEditingController(text: widget.perfil['apellido'] ?? '');
    _telefono = TextEditingController(text: widget.perfil['telefono'] ?? '');
    _correo = TextEditingController(text: widget.perfil['correo'] ?? '');
    _contrasena = TextEditingController();
    _direccion = TextEditingController(text: widget.perfil['direccion'] ?? '');
    _fechaNacimiento = widget.perfil['fechaNacimiento'] != null
        ? DateTime.tryParse(widget.perfil['fechaNacimiento'])
        : null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _direccion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _apellido,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: _telefono,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _correo,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _contrasena,
              decoration: const InputDecoration(labelText: 'Contraseña (dejar vacío si no cambia)'),
              obscureText: true,
            ),
            TextField(
              controller: _direccion,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_fechaNacimiento != null
                    ? 'Fecha: ${_fechaNacimiento!.toLocal().toIso8601String().substring(0, 10)}'
                    : 'Seleccionar fecha de nacimiento'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaNacimiento ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _fechaNacimiento = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop<Map<String, dynamic>>(context, {
              'nombre': _nombre.text,
              'apellido': _apellido.text,
              'telefono': _telefono.text,
              'correo': _correo.text,
              'contrasena': _contrasena.text.isNotEmpty ? _contrasena.text : null,
              'fechaNacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
              'direccion': _direccion.text,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}