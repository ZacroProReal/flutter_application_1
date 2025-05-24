import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agregar_producto.dart';
import 'actualizar_estado.dart';
import 'lista_productos.dart';
import 'login_page.dart';
import 'registro_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _usuarioLogueado = false;
  List<Map<String, dynamic>> _carritoItems = [];

  void iniciarSesion() {
    setState(() {
      _usuarioLogueado = true;
    });
  }

  void cerrarSesion() {
    setState(() {
      _usuarioLogueado = false;
      _carritoItems.clear();
    });
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final index =
          _carritoItems.indexWhere((p) => p['_id'] == producto['_id']);
      if (index >= 0) {
        _carritoItems[index]['cantidad'] += 1;
      } else {
        _carritoItems.add({
          ...producto,
          'cantidad': 1,
        });
      }
    });
  }

  void eliminarDelCarrito(int index) {
    setState(() {
      _carritoItems.removeAt(index);
    });
  }

  void vaciarCarrito() {
    setState(() {
      _carritoItems.clear();
    });
  }

  void actualizarCantidad(int index, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad > 0) {
        _carritoItems[index]['cantidad'] = nuevaCantidad;
      } else {
        _carritoItems.removeAt(index);
      }
    });
  }

  void _mostrarAlertaInicioSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inicio de sesión requerido'),
        content: const Text(
            'Debes iniciar sesión para acceder al carrito y realizar compras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(
                    onLoginSuccess: iniciarSesion,
                  ),
                ),
              );
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florezza 🌼',
      theme: ThemeData(
        primaryColor: Colors.pink[100],
        useMaterial3: true,
      ),
      home: HomeScreen(
        usuarioLogueado: _usuarioLogueado,
        onLogin: iniciarSesion,
        onLogout: cerrarSesion,
        carritoItems: _carritoItems,
        onAgregarAlCarrito: agregarAlCarrito,
        onEliminarDelCarrito: eliminarDelCarrito,
        onVaciarCarrito: vaciarCarrito,
        onActualizarCantidad: actualizarCantidad,
        mostrarAlertaInicioSesion: _mostrarAlertaInicioSesion,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool usuarioLogueado;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final List<Map<String, dynamic>> carritoItems;
  final Function(Map<String, dynamic>) onAgregarAlCarrito;
  final Function(int) onEliminarDelCarrito;
  final VoidCallback onVaciarCarrito;
  final Function(int, int) onActualizarCantidad;
  final Function(BuildContext) mostrarAlertaInicioSesion;

  const HomeScreen({
    required this.usuarioLogueado,
    required this.onLogin,
    required this.onLogout,
    required this.carritoItems,
    required this.onAgregarAlCarrito,
    required this.onEliminarDelCarrito,
    required this.onVaciarCarrito,
    required this.onActualizarCantidad,
    required this.mostrarAlertaInicioSesion,
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> productos = [];
  bool cargando = false;
  bool hayResultados = false;

  Future<void> buscarProductos(String query) async {
    if (query.isEmpty) return;

    setState(() {
      cargando = true;
    });

    try {
      final url = Uri.parse(
          'https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/buscar/$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          productos = data;
          hayResultados = true;
        });
      } else {
        setState(() {
          productos = [];
          hayResultados = true;
        });
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        productos = [];
        hayResultados = true;
      });
      print('Error al buscar productos: $e');
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: producto['imagen'] != null
            ? Image.memory(base64Decode(producto['imagen']),
                width: 50, fit: BoxFit.cover)
            : const Icon(Icons.image_not_supported),
        title: Text(producto['nombre'] ?? ''),
        subtitle: Text(producto['descripcion'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              producto['disponibilidad'] ? Icons.check_circle : Icons.cancel,
              color: producto['disponibilidad'] ? Colors.green : Colors.red,
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                if (!widget.usuarioLogueado) {
                  widget.mostrarAlertaInicioSesion(context);
                  return;
                }
                widget.onAgregarAlCarrito(producto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${producto['nombre']} agregado al carrito'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCarrito() {
    if (!widget.usuarioLogueado) {
      widget.mostrarAlertaInicioSesion(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tu Carrito (${widget.carritoItems.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: widget.carritoItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Tu carrito está vacío'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.carritoItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.carritoItems[index];
                          return Dismissible(
                            key: Key(item['_id'] ?? index.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              widget.onEliminarDelCarrito(index);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: item['imagen'] != null
                                    ? Image.memory(
                                        base64Decode(item['imagen']),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image, size: 50),
                                title: Text(item['nombre'] ?? 'Producto'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '\$${item['precio']?.toStringAsFixed(2) ?? '0.00'} c/u'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              size: 20),
                                          onPressed: () {
                                            final nuevaCantidad =
                                                item['cantidad'] - 1;
                                            widget.onActualizarCantidad(
                                                index, nuevaCantidad);
                                          },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text('${item['cantidad']}'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 20),
                                          onPressed: () {
                                            final nuevaCantidad =
                                                item['cantidad'] + 1;
                                            widget.onActualizarCantidad(
                                                index, nuevaCantidad);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.carritoItems.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '\$${_calcularTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onVaciarCarrito,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Vaciar Carrito'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _finalizarCompra(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[200],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Finalizar Compra'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _calcularTotal() {
    return widget.carritoItems.fold(
      0,
      (total, item) => total + (item['precio'] * item['cantidad']),
    );
  }

  void _finalizarCompra(BuildContext context) {
    if (!widget.usuarioLogueado) {
      widget.mostrarAlertaInicioSesion(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${_calcularTotal().toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('¿Deseas confirmar tu compra?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _procesarCompra(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _procesarCompra(BuildContext context) {
    final total = _calcularTotal();
    setState(() {
      widget.carritoItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compra realizada por \$${total.toStringAsFixed(2)}'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florezza 🌼'),
        backgroundColor: Colors.pink[100],
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _mostrarCarrito,
              ),
              if (widget.carritoItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${widget.carritoItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.usuarioLogueado)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      onLoginSuccess: widget.onLogin,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pink[100]),
              child: const Text(
                'Menú',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Agregar producto'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AgregarProductoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Actualizar estado'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ActualizarEstadoPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.pink[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: buscarProductos,
            ),
            const SizedBox(height: 10),
            if (cargando)
              const Center(child: CircularProgressIndicator())
            else if (hayResultados)
              Expanded(
                child: productos.isNotEmpty
                    ? ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) =>
                            _buildProductoCard(productos[index]),
                      )
                    : const Center(child: Text('No se encontraron productos')),
              )
            else
              Expanded(
                child: ListaProductosPage(
                  usuarioLogueado: widget.usuarioLogueado,
                  onAgregarAlCarrito: widget.onAgregarAlCarrito,
                  mostrarAlertaInicioSesion: widget.mostrarAlertaInicioSesion,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
