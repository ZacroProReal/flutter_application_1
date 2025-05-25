import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'carrito_service.dart';
import 'generar_factura_service.dart';
import 'FacturaPage.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final CarritoService _carritoService = CarritoService();
  List<dynamic> _productosEnCarrito = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final productos = await _carritoService.obtenerCarrito();
      setState(() {
        _productosEnCarrito = productos;
      });
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

  Future<void> _eliminarProducto(dynamic id) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _carritoService.eliminarProducto(id.toString());
      await _cargarCarrito();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _productosEnCarrito.isEmpty
                  ? const Center(child: Text('El carrito está vacío'))
                  : ListView.builder(
                      itemCount: _productosEnCarrito.length,
                      itemBuilder: (context, index) {
                        final item = _productosEnCarrito[index];
                        final cantidad = item['cantidad'] ?? 1;
                        final producto = item['producto'] ?? {};
                        final nombre = producto['nombre'] ?? 'Sin nombre';
                        final precio = producto['precio'] ?? 0;
                        final imagenBase64 = producto['imagen'];
                        final itemId = item['id'];
                        final itemIdStr = itemId?.toString() ?? '';

                        Widget leadingWidget;
                        if (imagenBase64 != null && imagenBase64.isNotEmpty) {
                          leadingWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              // Decodifica la imagen base64
                              Uri.parse('data:image/png;base64,$imagenBase64')
                                  .data!
                                  .contentAsBytes(),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                      Icons.image_not_supported),
                            ),
                          );
                        } else {
                          leadingWidget = const Icon(Icons.local_florist, size: 40);
                        }

                        // Badge para cantidad
                        Widget leadingWithBadge = Stack(
                          alignment: Alignment.topRight,
                          children: [
                            leadingWidget,
                            if (cantidad > 1)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$cantidad',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );

                        return Card(
                          color: Colors.pink[50], // Fondo rosado suave
                          margin:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            leading: leadingWithBadge,
                            title: Text(
                              nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Precio: \$${precio.toString()}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProducto(itemIdStr),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _productosEnCarrito.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.pink,
              icon: const Icon(Icons.payment),
              label: const Text('Realizar compra'),
              onPressed: () async {
                try {
                  final facturaService = GenerarFacturaService();
                  final factura = await facturaService.generarFactura();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacturaPage(factura: factura),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al generar factura: $e')),
                  );
                }
              },
            )
          : null,
    );
  }
}
