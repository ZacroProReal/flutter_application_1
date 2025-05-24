// facturapage.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FacturaPage extends StatefulWidget {
  final List<Map<String, dynamic>> carritoItems;
  final double total;
  final Function() onCompraFinalizada;
  final Map<String, dynamic>? factura; // Ahora es opcional (nullable)

  const FacturaPage({
    Key? key,
    required this.carritoItems, // Requerido ya que se usa para mostrar si 'factura' es null
    required this.total, // Requerido ya que se usa para mostrar si 'factura' es null
    required this.onCompraFinalizada,
    this.factura, // Parámetro opcional para datos de factura precargados
  }) : super(key: key);

  @override
  _FacturaPageState createState() => _FacturaPageState();
}

class _FacturaPageState extends State<FacturaPage> {
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _facturaData;

  @override
  void initState() {
    super.initState();
    // Si se pasan datos de factura, úsalos directamente. De lo contrario, genéralos.
    if (widget.factura == null) {
      _generarFactura();
    } else {
      _facturaData = widget.factura;
      // Si los datos están precargados y la compra está finalizada, llama al callback inmediatamente.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCompraFinalizada();
      });
    }
  }

  Future<void> _generarFactura() async {
    setState(() {
      _cargando = true;
      _error = null;
      _facturaData = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final int? usuarioId = prefs.getInt('usuarioId'); // Cambiado de Long a int
    final String? token = prefs.getString('token');

    if (usuarioId == null || token == null) {
      setState(() {
        _cargando = false;
        _error = 'Usuario no autenticado o ID/Token no encontrado.';
      });
      return;
    }

    const urlGenerarFactura =
        "https://tienda-virtual-de-flores-para-movil-1.onrender.com/Facturacion/generar";

    final List<Map<String, dynamic>> itemsParaFactura =
        widget.carritoItems.map((item) {
      return {'productoId': item['id'], 'cantidad': item['cantidad']};
    }).toList();

    try {
      final responseFactura = await http.post(
        Uri.parse(urlGenerarFactura),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuarioId': usuarioId,
          'items': itemsParaFactura,
        }),
      );

      if (responseFactura.statusCode == 200) {
        _facturaData = jsonDecode(responseFactura.body);
        print(
            'Datos de la factura recibidos: $_facturaData'); // Salida de depuración
        setState(() {
          // Este setState asegura que la UI se reconstruya con los datos.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura generada exitosamente.')),
        );
        widget
            .onCompraFinalizada(); // Llama al callback después de la generación exitosa
      } else {
        String errorMessage = 'Error desconocido al generar la factura.';
        try {
          final errorBody = jsonDecode(responseFactura.body);
          errorMessage =
              errorBody['message'] ?? errorBody['error'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              'Error al generar la factura: ${responseFactura.statusCode}';
        }
        print(
            'Error response: ${responseFactura.body}'); // Salida de depuración
        setState(() {
          _cargando = false;
          _error = errorMessage;
        });
      }
    } catch (e) {
      print('Error de red/API: $e'); // Salida de depuración
      setState(() {
        _cargando = false;
        _error = 'Error de conexión o API: $e';
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
      appBar: AppBar(
        title: const Text('Factura'),
        backgroundColor: Colors.green[400],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text('Error al generar la factura:',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              _generarFactura, // Permite reintentar la llamada a la API
                          child: const Text('Reintentar'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Volver al carrito
                          },
                          child: const Text('Volver al Carrito'),
                        ),
                      ],
                    ),
                  ),
                )
              : _facturaData !=
                      null // Comprueba si los datos de la factura están disponibles para mostrar
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Número de Factura: ${_facturaData?['numeroFactura'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(
                              'Fecha de Emisión: ${_facturaData?['fechaEmision'] ?? 'N/A'}'),
                          const SizedBox(height: 16),
                          const Text('Detalles del Cliente:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              'Nombre: ${_facturaData?['receptorNombre'] ?? 'N/A'} ${_facturaData?['receptorApellido'] ?? 'N/A'}'),
                          Text(
                              'Correo: ${_facturaData?['receptorCorreo'] ?? 'N/A'}'),
                          Text(
                              'Teléfono: ${_facturaData?['receptorTelefono'] ?? 'N/A'}'), // Añadido teléfono
                          const SizedBox(height: 16),
                          const Text('Detalles de los ítems:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          // Muestra los artículos de _facturaData, no necesariamente de widget.carritoItems
                          // porque la respuesta del servidor es la fuente autorizada para la factura.
                          if (_facturaData?['items'] != null)
                            ...(_facturaData!['items'] as List).map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            '${item['descripcionProducto']} x ${item['cantidad']}')),
                                    Text(
                                        '\$${(item['total'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                                  ],
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '\$${(_facturaData?['subtotal'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Impuestos (19%):',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '\$${(_facturaData?['impuestos'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text(
                                  '\$${(_facturaData?['total'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Corrección: textAlign se aplica directamente al widget Text, no al TextStyle
                          const Text('¡Gracias por tu compra!',
                              textAlign:
                                  TextAlign.center, // <-- textAlign movido aquí
                              style: TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.popUntil(
                                    context,
                                    (route) =>
                                        route.isFirst); // Volver al inicio
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[300],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: const Text('Volver al inicio'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('Generando factura...')),
    );
  }
}
