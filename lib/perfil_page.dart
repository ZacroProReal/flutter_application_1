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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}