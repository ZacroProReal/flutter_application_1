import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'registro_page.dart';
import 'agregar_producto.dart';
import 'actualizar_estado.dart';
import 'CarritoPage.dart';
import 'lista_productos.dart';
import 'perfil_page.dart';

void main() {
  runApp(const FlorezzaApp());
}

class FlorezzaApp extends StatelessWidget {
  const FlorezzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florezza 🌼',
      theme: ThemeData(
        primaryColor: Colors.pink[100],
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink[100]!,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _usuarioEmail;
  bool _usuarioLogueado = false;
  final TextEditingController _buscarController = TextEditingController();
  String _busqueda = '';
  Key _listaProductosKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final sesionIniciada = prefs.getBool('sesionIniciada') ?? false;
    if (sesionIniciada) {
      setState(() {
        _usuarioEmail = prefs.getString('usuarioEmail');
        _usuarioLogueado = true;
      });
    } else {
      setState(() {
        _usuarioEmail = null;
        _usuarioLogueado = false;
      });
    }
  }

  void _abrirLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLoginSuccess: _cargarSesion,
          onTokenReceived: (token) {
            print("Token recibido en main.dart: $token");
          },
        ),
      ),
    );
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilPage()),
    );
  }

  void _abrirAgregarProducto() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgregarProductoPage()),
    );
    if (resultado == true && mounted) {
      setState(() {
        _listaProductosKey = UniqueKey(); // Fuerza el rebuild
        _busqueda = '';
      });
    }
  }

  void _abrirActualizarEstado() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActualizarEstadoPage()),
    );
  }

  void _abrirCarrito() {
    if (_usuarioLogueado) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CarritoPage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No ha iniciado sesión'),
          content: const Text('Debe iniciar sesión para ver el carrito.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                _abrirLogin(); // Abre la página de login
              },
              child: const Text('Iniciar sesión'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    }
  }

  void _mostrarAlertaInicioSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debe iniciar sesión'),
        content: const Text('Por favor, inicie sesión para agregar productos al carrito.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirLogin();
            },
            child: const Text('Iniciar sesión'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarProductoAlCarrito(Map<String, dynamic> producto) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _mostrarAlertaInicioSesion(context);
      return;
    }
    try {
      // Usa siempre el campo 'id' y conviértelo a string
      final productoId = producto['id']?.toString() ?? '';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${producto['nombre']} agregado al carrito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar el producto al carrito')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onBuscar() {
    setState(() {
      _busqueda = _buscarController.text.trim();
    });
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
            tooltip: 'Carrito',
            onPressed: _abrirCarrito,
          ),
          IconButton(
            icon: _usuarioLogueado
                ? const Icon(Icons.account_circle)
                : const Icon(Icons.person),
            tooltip: _usuarioLogueado
                ? 'Ver perfil'
                : 'Iniciar Sesión',
            onPressed: _usuarioLogueado
                ? _abrirPerfil
                : _abrirLogin,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pink[100],
              ),
              child: const Text(
                'Menú Florezza',
                style: TextStyle(fontSize: 24, color: Colors.black87),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Agregar producto'),
              onTap: () {
                Navigator.pop(context); // Cierra el Drawer
                _abrirAgregarProducto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Actualizar estado'),
              onTap: () {
                Navigator.pop(context); // Cierra el Drawer
                _abrirActualizarEstado();
              },
            ),
            if (_usuarioLogueado)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  await prefs.remove('usuarioEmail');
                  await prefs.setBool('sesionIniciada', false);
                  setState(() {
                    _usuarioEmail = null;
                    _usuarioLogueado = false;
                  });
                  Navigator.pop(context); // Cierra el Drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión cerrada')),
                  );
                },
              ),
          ],
        ),
      ),
      body: ListaProductosPage(
        key: _listaProductosKey, // <-- aquí
        usuarioLogueado: _usuarioLogueado,
        onAgregarAlCarrito: _agregarProductoAlCarrito,
        mostrarAlertaInicioSesion: _mostrarAlertaInicioSesion,
        busqueda: _busqueda,
      ),
    );
  }
}