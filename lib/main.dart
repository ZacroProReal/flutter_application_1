import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agregar_producto.dart';
import 'actualizar_estado.dart';
import 'lista_productos.dart';
import 'agregar_carrito.dart';
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

  void iniciarSesion() {
    setState(() {
      _usuarioLogueado = true;
    });
  }

  void cerrarSesion() {
    setState(() {
      _usuarioLogueado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florezza 🌼.',
      theme: ThemeData(
        primaryColor: Colors.pink[100],
        useMaterial3: true,
      ),
      home: HomeScreen(
        usuarioLogueado: _usuarioLogueado,
        onLogin: iniciarSesion,
        onLogout: cerrarSesion,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool usuarioLogueado;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const HomeScreen({
    required this.usuarioLogueado,
    required this.onLogin,
    required this.onLogout,
  });

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
        trailing: Icon(
          producto['disponibilidad'] ? Icons.check_circle : Icons.cancel,
          color: producto['disponibilidad'] ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  void _manejarCarrito() {
    if (widget.usuarioLogueado) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CarritoPage(
                  carritoItems: [],
                )),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => LoginPage(
                  onLoginSuccess: widget.onLogin,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florezza 🌼'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _manejarCarrito,
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
                          )),
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
              Expanded(child: ListaProductosPage()),
          ],
        ),
      ),
    );
  }
}
