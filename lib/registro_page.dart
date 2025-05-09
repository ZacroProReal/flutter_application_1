import 'package:flutter/material.dart';

class RegistroPage extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegistroPage({required this.onRegisterSuccess, super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  DateTime? _fechaNacimiento;
  String _prefijo = '+57';

  bool _cargando = false;

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    // Aquí podrías enviar los datos a un servidor (por ahora es solo simulación)
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _cargando = false);
    widget.onRegisterSuccess();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Florezza 🌼',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _prefijo,
                    onChanged: (value) {
                      setState(() {
                        _prefijo = value!;
                      });
                    },
                    items: ['+57', '+1', '+34', '+52']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _contrasenaController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Fecha de nacimiento:'),
                  const SizedBox(width: 10),
                  Text(
                    _fechaNacimiento == null
                        ? 'dd / mm / yyyy'
                        : '${_fechaNacimiento!.day} / ${_fechaNacimiento!.month} / ${_fechaNacimiento!.year}',
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _seleccionarFecha(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargando ? null : _crearCuenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                ),
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
