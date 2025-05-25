import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarritoService {
  static const String baseUrl = 'https://tienda-virtual-de-flores-para-movil-1.onrender.com';

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> obtenerCarrito() async {
    final token = await _obtenerToken();
    if (token == null) throw Exception('Usuario no autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/carrito/productos'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Devuelve la lista directamente
      if (data is List) {
        return data;
      }
      throw Exception('Respuesta inesperada del servidor');
    } else {
      throw Exception('Error al obtener carrito: ${response.statusCode}');
    }
  }

  Future<void> eliminarProducto(String productoId) async {
    final token = await _obtenerToken();
    if (token == null) throw Exception('Usuario no autenticado');

    final response = await http.delete(
      Uri.parse('$baseUrl/carrito/eliminar-producto/$productoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto: ${response.statusCode}');
    }
  }
}
