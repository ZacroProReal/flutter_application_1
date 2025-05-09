import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ListaProductosPage extends StatefulWidget {
  @override
  _ListaProductosPageState createState() => _ListaProductosPageState();
}

class _ListaProductosPageState extends State<ListaProductosPage> {
  List<dynamic> productos = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    obtenerProductos();
  }

  Future<void> obtenerProductos() async {
    setState(() {
      cargando = true;
    });

    try {
      final url = Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          productos = jsonDecode(response.body);
        });
      } else {
        print('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al obtener productos: $e');
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  void agregarAlCarrito(dynamic producto) {
    // Aquí puedes agregar la lógica para añadir al carrito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${producto['nombre']} agregado al carrito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Productos'),
        backgroundColor: Colors.pink[100],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // dos columnas
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: producto['imagen'] != null
                                ? Image.memory(
                                    base64Decode(producto['imagen']),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$ ${producto['precio']?.toString() ?? '0'}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    producto['disponibilidad']
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: producto['disponibilidad']
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    producto['disponibilidad'] ? 'Disponible' : 'No disponible',
                                    style: TextStyle(
                                      color: producto['disponibilidad'] ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => agregarAlCarrito(producto),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink[200],
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Agregar al carrito'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
