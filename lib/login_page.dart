import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final Function(String)? onTokenReceived;

  const LoginPage({
    required this.onLoginSuccess,
    this.onTokenReceived,
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  bool _tokenGuardado = false;
  String? _error;

  Future<void> _guardarSesion(String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesionIniciada', true);
    await prefs.setString('usuarioEmail', email);
    await prefs.setString('token', token);
    setState(() {
      _tokenGuardado = true;
    });
  }

  Future<void> _login() async {
    setState(() {
      _cargando = true;
      _error = null;
      _tokenGuardado = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _cargando = false;
        _error = 'Por favor complete todos los campos';
      });
      return;
    }

    const url = "https://tienda-virtual-de-flores-para-movil-1.onrender.com/autenticacion/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'contrasena': password}),
      );

      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String? token = responseData['token'];
        if (token != null && token.isNotEmpty) {
          print('Token recibido: $token');
          await _guardarSesion(email, token);

          if (widget.onTokenReceived != null) {
            widget.onTokenReceived!(token);
          }

          widget.onLoginSuccess();

          if (mounted) {
            Navigator.pop(context); // Cierra pantalla de login
          }
        } else {
          setState(() {
            _error = 'No se recibió el token. Intente de nuevo.';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = responseData['mensaje'] ?? 'Credenciales inválidas';
        });
      } else {
        setState(() {
          _error = responseData['mensaje'] ?? 'Error en el servidor (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroPage(
          onRegisterSuccess: () {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registro exitoso. Por favor inicie sesión.'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final camposHabilitados = !_cargando && !_tokenGuardado;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                enabled: camposHabilitados,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                enabled: camposHabilitados,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_cargando) const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: camposHabilitados ? _login : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ingresar'),
              ),
              TextButton(
                onPressed: camposHabilitados ? _irARegistro : null,
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
