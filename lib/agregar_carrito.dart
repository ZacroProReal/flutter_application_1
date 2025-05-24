// agregar_carrito.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Necesario para base64Decode
import 'facturapage.dart'; // Importa la página de factura

class AgregarAlCarritoPage extends StatefulWidget {
  final List<Map<String, dynamic>> carritoItems;
  final Function() onVaciarCarrito;
  final Function(int, int) onActualizarCantidad;
  final Function(int) onEliminarDelCarrito;
  final bool usuarioLogueado;
  final Function(BuildContext) mostrarAlertaInicioSesion;
  final Function()
      onCompraFinalizada; // Callback para cuando se finaliza la compra

  const AgregarAlCarritoPage({
    Key? key,
    required this.carritoItems,
    required this.onVaciarCarrito,
    required this.onActualizarCantidad,
    required this.onEliminarDelCarrito,
    required this.usuarioLogueado,
    required this.mostrarAlertaInicioSesion,
    required this.onCompraFinalizada,
  }) : super(key: key);

  @override
  _AgregarAlCarritoPageState createState() => _AgregarAlCarritoPageState();
}

class _AgregarAlCarritoPageState extends State<AgregarAlCarritoPage> {
  double _calcularTotal() {
    return widget.carritoItems.fold(
      0,
      (total, item) => total + (item['precio'] * item['cantidad']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Carrito'),
        backgroundColor: Colors.pink[100],
      ),
      body: widget.carritoItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tu carrito está vacío', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.carritoItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.carritoItems[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: item['imagen'] != null &&
                                  item['imagen'].isNotEmpty
                              ? Image.memory(
                                  base64Decode(item['imagen']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons
                                          .broken_image), // Builder de error para imágenes
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
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: () {
                                      // Asegúrate de que la cantidad no baje de 1
                                      if (item['cantidad'] > 1) {
                                        final nuevaCantidad =
                                            item['cantidad'] - 1;
                                        widget.onActualizarCantidad(
                                            index, nuevaCantidad);
                                      } else {
                                        // Si la cantidad es 1 y se intenta decrementar, elimina el artículo
                                        widget.onEliminarDelCarrito(index);
                                      }
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
                          trailing: IconButton(
                            // Botón de eliminar para cada artículo
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              widget.onEliminarDelCarrito(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${_calcularTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onVaciarCarrito,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Vaciar Carrito'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (!widget.usuarioLogueado) {
                                  widget.mostrarAlertaInicioSesion(context);
                                  return;
                                }
                                if (widget.carritoItems.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'El carrito está vacío. Agrega productos para continuar.')),
                                  );
                                  return;
                                }
                                // Navega a la página de factura, pasando todos los parámetros requeridos
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FacturaPage(
                                      carritoItems: widget
                                          .carritoItems, // Pasa la lista de artículos
                                      total:
                                          _calcularTotal(), // Pasa el total calculado
                                      onCompraFinalizada: widget
                                          .onCompraFinalizada, // Pasa el callback
                                      // El parámetro 'factura' es opcional en FacturaPage,
                                      // ya que FacturaPage llamará a la API si 'factura' es null.
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Ir a Factura',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
