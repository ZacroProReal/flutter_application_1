import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DetalleProductoPage extends StatefulWidget {
  final String nombreProducto;

  const DetalleProductoPage({required this.nombreProducto, super.key});

  @override
  State<DetalleProductoPage> createState() => _DetalleProductoPageState();
}

class _DetalleProductoPageState extends State<DetalleProductoPage> {
  Map<String, dynamic>? producto;
  bool cargando = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    final url = Uri.parse(
        'https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/buscar/${widget.nombreProducto}');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        setState(() {
          producto = json.decode(resp.body);
          cargando = false;
        });
      } else {
        setState(() {
          error = 'No se encontró el producto';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error al cargar producto';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: Center(child: Text(error)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(producto?['nombre'] ?? 'Detalle'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleProductoPage(nombreProducto: producto!['nombre']),
                  ),
                );
              },
              child: producto?['imagen'] != null && producto!['imagen'].isNotEmpty
                  ? Image.memory(
                      base64Decode(producto!['imagen']),
                      fit: BoxFit.cover,
                      height: 120,
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 60),
                    ),
            ),
            const SizedBox(height: 16),
            Text('${producto?['nombre'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Descripción: ${producto?['descripcion'] ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Costo: \$${producto?['precio'] ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Cantidad disponible: ${producto?['cantidadDisponible'] ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Color de flores: ${producto?['colorFlores'] ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Disponible: ${producto?['disponibilidad'] == true ? "Sí" : "No"}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (producto?['disponibilidad'] == true)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Añadir al carrito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  // Obtener token de sesión
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  if (token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe iniciar sesión para agregar al carrito')),
                    );
                    return;
                  }
                  final productoId = producto?['id']?.toString() ?? '';
                  if (productoId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID de producto no válido')),
                    );
                    return;
                  }
                  final response = await http.post(
                    Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/carrito/agregar-producto/$productoId'),
                    headers: {'Authorization': 'Bearer $token'},
                  );
                  if (response.statusCode == 200) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${producto?['nombre']} agregado al carrito')),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst); // Regresa al menú inicial
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo agregar el producto al carrito')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}