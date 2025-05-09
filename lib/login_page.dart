import 'package:flutter/material.dart';
import 'registro_page.dart'; // Asegúrate de que el nombre coincida con el archivo real

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({required this.onLoginSuccess, super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  String? _error;

  void _login() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    // Simulación de autenticación
    if (email == 'demo@demo.com' && password == '1234') {
      widget.onLoginSuccess();
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'Credenciales inválidas';
      });
    }

    setState(() {
      _cargando = false;
    });
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroPage(
          onRegisterSuccess: () {
            Navigator.pop(context); // Cierra la pantalla de registro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario registrado con éxito')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_cargando) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _cargando ? null : _login,
              child: const Text('Ingresar'),
            ),
            TextButton(
              onPressed: _irARegistro,
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
