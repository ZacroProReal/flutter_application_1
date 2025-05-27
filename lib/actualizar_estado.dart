import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActualizarEstadoPage extends StatefulWidget {
  const ActualizarEstadoPage({super.key});

  @override
  State<ActualizarEstadoPage> createState() => _ActualizarEstadoPageState();
}

class _ActualizarEstadoPageState extends State<ActualizarEstadoPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  bool? _disponibilidad;
  int? _productoId;

  Future<void> buscarProducto() async {
    final nombre = _nombreController.text;
    final url = Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/buscar/$nombre');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() {
        _productoId = data['id'];
        _precioController.text = data['precio'].toString();
        _cantidadController.text = data['cantidadDisponible'].toString();
        _descripcionController.text = data['descripcion'] ?? '';
        _disponibilidad = data['disponibilidad'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
    }
  }

  Future<void> actualizarProducto() async {
    if (_productoId == null) return;
    final url = Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/modificar/$_productoId');
    final body = json.encode({
      "nombre": _nombreController.text,
      "descripcion": _descripcionController.text,
      "precio": int.tryParse(_precioController.text) ?? 0,
      "cantidadDisponible": int.tryParse(_cantidadController.text) ?? 0,
      "disponibilidad": _disponibilidad,
    });
    final resp = await http.put(url,
        headers: {'Content-Type': 'application/json'}, body: body);
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Producto'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: buscarProducto,
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 20),
            if (_productoId != null) ...[
              TextField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad Disponible',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Disponible'),
                      value: true,
                      groupValue: _disponibilidad,
                      onChanged: (val) => setState(() => _disponibilidad = val),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No disponible'),
                      value: false,
                      groupValue: _disponibilidad,
                      onChanged: (val) => setState(() => _disponibilidad = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: actualizarProducto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                ),
                child: const Text('Actualizar'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
