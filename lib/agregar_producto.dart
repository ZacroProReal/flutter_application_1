import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController colorFloresController = TextEditingController();
  final TextEditingController cantidadDisponibleController =
      TextEditingController();
  bool disponibilidad = true;
  Uint8List? imagenBytes;

  Future<void> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        imagenBytes = bytes;
      });
    }
  }

  Future<void> agregarProducto() async {
    final url = Uri.parse(
        'https://tienda-virtual-de-flores-para-movil-1.onrender.com/productos/');
    final Map<String, dynamic> producto = {
      'nombre': nombreController.text,
      'descripcion': descripcionController.text,
      'precio': double.tryParse(valorController.text) ?? 0.0,
      'cantidadDisponible':
          int.tryParse(cantidadDisponibleController.text) ?? 0,
      'colorFlores': colorFloresController.text,
      'disponibilidad': disponibilidad,
      'imagen': imagenBytes != null ? base64Encode(imagenBytes!) : null,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // ← aquí se regresa correctamente
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar producto')),
      );
    }
  }

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
    valorController.clear();
    colorFloresController.clear();
    cantidadDisponibleController.clear();
    imagenBytes = null;
    disponibilidad = true;
    setState(() {});
  }

  Widget buildTextField(String label, TextEditingController controller,
      {String? prefix, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          suffixIcon: icon != null ? Icon(icon) : const Icon(Icons.edit),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildTextField('Nombre', nombreController),
            buildTextField('Descripción', descripcionController),
            buildTextField('Valor', valorController, prefix: '\$'),
            buildTextField('Color de flores', colorFloresController),
            buildTextField('Cantidad disponible', cantidadDisponibleController),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Disponibilidad',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: disponibilidad,
                  onChanged: (value) {
                    setState(() {
                      disponibilidad = value;
                    });
                  },
                ),
                Icon(
                  disponibilidad ? Icons.circle : Icons.circle_outlined,
                  color: disponibilidad ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: seleccionarImagen,
              icon: const Icon(Icons.image),
              label: const Text('Seleccionar imagen'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pink[100]),
            ),
            if (imagenBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.memory(imagenBytes!, height: 150),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: agregarProducto,
              child: const Text('Agregar producto'),
            )
          ],
        ),
      ),
    );
  }
}
