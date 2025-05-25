import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences

class ListaProductosPage extends StatefulWidget {
  final bool usuarioLogueado;
  final Function(Map<String, dynamic>) onAgregarAlCarrito;
  final Function(BuildContext) mostrarAlertaInicioSesion;
  final String busqueda; // <-- nuevo parámetro

  const ListaProductosPage({
    required this.usuarioLogueado,
    required this.onAgregarAlCarrito,
    required this.mostrarAlertaInicioSesion,
    this.busqueda = '',
    Key? key,
  }) : super(key: key);

  @override
  _ListaProductosPageState createState() => _ListaProductosPageState();
}

class _ListaProductosPageState extends State<ListaProductosPage> {
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  bool _cargando = false;
  String _error = '';
  final TextEditingController _buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerProductos();
  }

  @override
  void didUpdateWidget(covariant ListaProductosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busqueda != oldWidget.busqueda) {
      _buscarController.text = widget.busqueda;
      _buscarProducto();
    }
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
            _productosFiltrados = data;
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

  void _buscarProducto() {
    final query = _buscarController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _productosFiltrados = _productos;
      });
    } else {
      setState(() {
        _productosFiltrados = _productos
            .where((producto) =>
                (producto['nombre'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query))
            .toList();
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
      return Center(child: Text(_error));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Barra de búsqueda debajo del AppBar y arriba de la lista
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscarController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _buscarProducto(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _buscarProducto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _productosFiltrados.isEmpty
                ? const Center(child: Text('No hay productos disponibles'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosFiltrados[index];
                      return _buildProductoCard(producto);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
