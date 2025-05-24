import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences

class ListaProductosPage extends StatefulWidget {
  final bool usuarioLogueado;
  final Function(Map<String, dynamic>) onAgregarAlCarrito;
  final Function(BuildContext) mostrarAlertaInicioSesion;

  const ListaProductosPage({
    required this.usuarioLogueado,
    required this.onAgregarAlCarrito,
    required this.mostrarAlertaInicioSesion,
    Key? key,
  }) : super(key: key);

  @override
  _ListaProductosPageState createState() => _ListaProductosPageState();
}

class _ListaProductosPageState extends State<ListaProductosPage> {
  List<dynamic> _productos = [];
  bool _cargando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _obtenerProductos();
  }

  Future<void> _obtenerProductos() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final url = Uri.parse(
          'https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _productos = data;
          });
        } else {
          throw Exception('Formato de datos inesperado');
        }
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final nombre = producto['nombre'] ?? 'Sin nombre';
    final precio = producto['precio']?.toString() ?? '0';
    final disponible = producto['disponibilidad'] == true;
    final imagen = producto['imagen'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imagen != null
                  ? Image.memory(
                      base64Decode(imagen),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$$precio',
                  style: TextStyle(
                      color: Colors.pink[800], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      disponible ? Icons.check_circle : Icons.cancel,
                      color: disponible ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      disponible ? 'Disponible' : 'No disponible',
                      style: TextStyle(
                        color: disponible ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (!widget.usuarioLogueado) {
                      widget.mostrarAlertaInicioSesion(context);
                      return;
                    }
                    widget.onAgregarAlCarrito(producto);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$nombre agregado al carrito'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[200],
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Agregar al carrito',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Error al cargar productos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _obtenerProductos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_productos.isEmpty) {
      return const Center(
        child: Text('No hay productos disponibles'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _productos.length,
        itemBuilder: (context, index) {
          final producto = _productos[index];
          return _buildProductoCard(producto);
        },
      ),
    );
  }
}
