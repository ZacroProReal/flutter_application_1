import 'package:flutter/material.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key, required this.carritoItems});

  final List<String> carritoItems;

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  late List<String> _carritoItems;
  // Mapa para almacenar la cantidad de cada producto en el carrito
  final Map<String, int> _cantidadProductos = {};

  @override
  void initState() {
    super.initState();
    _carritoItems = List.from(widget.carritoItems); // Crea una copia mutable
    // Inicializa la cantidad de cada producto en 1
    for (var item in _carritoItems) {
      _cantidadProductos[item] = (_cantidadProductos[item] ?? 0) + 1;
    }
    // Actualiza la lista para que solo contenga productos únicos
    _carritoItems = _cantidadProductos.keys.toList();
  }

  void _incrementarCantidad(String producto) {
    setState(() {
      _cantidadProductos[producto] = (_cantidadProductos[producto] ?? 0) + 1;
    });
  }

  void _decrementarCantidad(String producto) {
    setState(() {
      if (_cantidadProductos[producto] != null &&
          _cantidadProductos[producto]! > 1) {
        _cantidadProductos[producto] = _cantidadProductos[producto]! - 1;
      } else {
        _eliminarProducto(producto); // Si la cantidad es 1, decrementar elimina
      }
    });
  }

  void _eliminarProducto(String producto) {
    setState(() {
      _cantidadProductos.remove(producto);
      _carritoItems.remove(producto);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        backgroundColor: Colors.pink[100],
      ),
      body: _carritoItems.isEmpty
          ? const Center(
              child: Text('El carrito está vacío'),
            )
          : ListView.builder(
              itemCount: _carritoItems.length,
              itemBuilder: (context, index) {
                final producto = _carritoItems[index];
                final cantidad = _cantidadProductos[producto] ?? 0;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(producto),
                    subtitle: Row(
                      children: [
                        const Text('Cantidad: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _decrementarCantidad(producto),
                        ),
                        Text('$cantidad'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _incrementarCantidad(producto),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarProducto(producto),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _carritoItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // Aquí podrías pasar la información del carrito actualizado de vuelta a HomeScreen si fuera necesario
                Navigator.pop(context, _cantidadProductos);
              },
              backgroundColor: Colors.pink[200],
              child: const Icon(Icons.check, color: Colors.white),
            )
          : null,
    );
  }
}
