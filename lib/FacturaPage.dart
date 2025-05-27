import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'carrito_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io' as io; // Para móvil/escritorio

// Solo para web, importa dart:html como io
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as io_web;

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
  final CarritoService _carritoService = CarritoService();

  Future<void> _realizarCompra() async {
    if (_descargando) return;
    setState(() {
      _descargando = true;
    });
    try {
      setState(() {
        _pdfUrl = 'https://tienda-virtual-de-flores-para-movil-1.onrender.com/Facturacion/obtener';
        _compraRealizada = true;
      });

      // Mensaje emergente de compra exitosa
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Compra realizada!'),
          content: const Text('Tu compra fue exitosa. Ahora puedes descargar tu factura en PDF.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la compra: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _descargando = false;
        });
      }
    }
  }

  Future<void> _descargarPDF() async {
    if (_pdfUrl != null) {
      setState(() {
        _descargando = true;
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debe iniciar sesión para descargar la factura')),
          );
          return;
        }
        final uri = Uri.parse(_pdfUrl!);
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;

          String? savePath;
          if (kIsWeb) {
            // Lógica para web: descarga usando AnchorElement
            final blob = io_web.Blob([bytes], 'application/pdf');
            final url = io_web.Url.createObjectUrlFromBlob(blob);
            final anchor = io_web.AnchorElement(href: url)
              ..setAttribute('download', 'factura.pdf')
              ..style.display = 'none';
            io_web.document.body!.children.add(anchor);
            anchor.click();
            io_web.document.body!.children.remove(anchor);
            io_web.Url.revokeObjectUrl(url);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Factura PDF descargada.')),
            );
          } else if (!(io.Platform.isAndroid || io.Platform.isIOS)) {
            // Escritorio: pedir carpeta al usuario
            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory != null) {
              savePath = '$selectedDirectory/factura.pdf';
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se seleccionó carpeta')),
              );
              return;
            }
          } else {
            // Móvil: carpeta de documentos
            final dir = await getApplicationDocumentsDirectory();
            savePath = '${dir.path}/factura.pdf';
          }

          if (!kIsWeb) {
            final file = await io.File(savePath!).writeAsBytes(bytes);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Factura PDF guardada en: $savePath')),
            );

            await OpenFile.open(file.path);
          }

          // Ahora sí, eliminar los productos del carrito
          final productos = await _carritoService.obtenerCarrito();
          if (productos.isNotEmpty) {
            for (var item in productos) {
              final nombreProducto = item['producto']['nombre'];
              if (nombreProducto != null) {
                final url = Uri.parse('https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/buscar/$nombreProducto');
                final resp = await http.get(url);
                if (resp.statusCode == 200) {
                  final data = jsonDecode(resp.body);
                  final productoId = data['id'];
                  if (productoId != null) {
                    try {
                      await _carritoService.eliminarProducto(productoId.toString());
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar producto $productoId: $e')),
                      );
                    }
                  }
                }
              }
            }
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al descargar PDF: ${response.statusCode}')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar PDF: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _descargando = false;
          });
        }
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