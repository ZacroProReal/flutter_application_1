import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BuscarProductoPage extends StatefulWidget {
  @override
  _BuscarProductoPageState createState() => _BuscarProductoPageState();
}

class _BuscarProductoPageState extends State<BuscarProductoPage> {
  final TextEditingController buscarController = TextEditingController();
  List<dynamic> productos = [];

  Future<void> buscarProducto() async {
    final query = buscarController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/buscar/$query');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> resultados = jsonDecode(response.body);
        setState(() {
          productos = resultados;
        });
      } else {
        setState(() {
          productos = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontraron productos')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al buscar producto')),
      );
    }
  }

  Widget buildProductoCard(dynamic producto) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(producto['nombre']),
        subtitle: Text(producto['descripcion'] ?? ''),
        trailing: Icon(
          producto['disponibilidad'] ? Icons.check_circle : Icons.cancel,
          color: producto['disponibilidad'] ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Producto'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: buscarController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: buscarProducto,
                ),
              ),
              onSubmitted: (_) => buscarProducto(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: productos.isEmpty
                  ? const Center(child: Text('No hay resultados'))
                  : ListView.builder(
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        return buildProductoCard(productos[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
