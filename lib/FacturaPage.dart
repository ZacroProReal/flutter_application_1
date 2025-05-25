import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'carrito_service.dart';

class FacturaPage extends StatefulWidget {
  final Map<String, dynamic> factura;
  const FacturaPage({super.key, required this.factura});

  @override
  State<FacturaPage> createState() => _FacturaPageState();
}

class _FacturaPageState extends State<FacturaPage> {
  bool _compraRealizada = false;
  String? _pdfUrl;
  bool _descargando = false;

  Future<void> _realizarCompra() async {
    if (_descargando) return;
    setState(() {
      _descargando = true;
    });
    try {
      // Elimina productos del carrito solo si hay productos
      final carritoService = CarritoService();
      final productos = await carritoService.obtenerCarrito();
      if (productos.isNotEmpty) {
        for (var item in productos) {
          await carritoService.eliminarProducto(item['id'].toString());
        }
      }

      // Obtiene el PDF de la factura
      final numeroFactura = widget.factura['numeroFactura'];
      final url = 'https://tienda-virtual-de-flores-para-movil-1.onrender.com/Facturacion/obtener?numeroFactura=$numeroFactura';
      setState(() {
        _pdfUrl = url;
        _compraRealizada = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la compra: $e')),
      );
    } finally {
      setState(() {
        _descargando = false;
      });
    }
  }

  Future<void> _descargarPDF() async {
    if (_pdfUrl != null) {
      final uri = Uri.parse(_pdfUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final factura = widget.factura;
    final items = factura['items'] as List<dynamic>? ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Factura generada')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Factura N°: ${factura['numeroFactura']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Emisor: ${factura['emisorNombre']}'),
            Text('NIT: ${factura['emisorNif']}'),
            Text('Dirección: ${factura['emisorDireccion']}'),
            const Divider(),
            Text('Cliente: ${factura['receptorNombre']} ${factura['receptorApellido']}'),
            Text('Correo: ${factura['receptorCorreo']}'),
            Text('Teléfono: ${factura['receptorTelefono']}'),
            const Divider(),
            Text('Fecha: ${factura['fechaEmision']}'),
            const Divider(),
            const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...items.map((item) => ListTile(
                  title: Text(item['descripcionProducto']),
                  subtitle: Text('Cantidad: ${item['cantidad']} x \$${item['precioUnitario']}'),
                  trailing: Text('\$${item['total']}'),
                )),
            const Divider(),
            Text('Subtotal: \$${factura['subtotal']}'),
            Text('Impuestos: \$${factura['impuestos']}'),
            Text('Total: \$${factura['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Forma de pago: ${factura['formaDePago']}'),
            Text('Condiciones: ${factura['condicionesVenta']}'),
            const SizedBox(height: 24),
            if (!_compraRealizada)
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag),
                label: _descargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Comprar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _descargando ? null : _realizarCompra,
              ),
            if (_compraRealizada && _pdfUrl != null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar factura PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _descargarPDF,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}