import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences

class RegistroPage extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegistroPage({required this.onRegisterSuccess, super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  DateTime? _fechaNacimiento;

  Future<void> _registrarUsuario() async {
    debugPrint('Iniciando registro de usuario...');
    if (!_formKey.currentState!.validate() || _fechaNacimiento == null) {
      debugPrint('Validación fallida: campos incompletos');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    final url = Uri.parse(
        'https://tienda-virtual-de-flores-para-movil-1.onrender.com/usuarios/registrar');
    final payload = {
      'nombre': _nombreController.text,
      'apellido': _apellidoController.text,
      'telefono': _telefonoController.text,
      'correo': _correoController.text,
      'contrasena': _contrasenaController.text,
      'fechaNacimiento': _fechaNacimiento!.toIso8601String().split('T')[0],
      'direccion': _direccionController.text, // Nuevo campo
    };

    debugPrint('Payload enviado: $payload');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('Código de respuesta: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Registro exitoso');
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('sesionIniciada', true);
        }

        widget.onRegisterSuccess();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado con éxito')),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        debugPrint('Error al registrar usuario');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Excepción durante el registro: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excepción: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaNacimiento) {
      print('Fecha seleccionada: $picked');
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Cargando pantalla de registro');
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _contrasenaController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _fechaNacimiento != null
                        ? 'Fecha: ${_fechaNacimiento!.toLocal().toIso8601String().substring(0, 10)}'
                        : 'Seleccionar fecha de nacimiento',
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Elegir Fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrarUsuario,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
