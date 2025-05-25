import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GenerarFacturaService {
  static const String baseUrl = 'https://tienda-virtual-de-flores-para-movil-1.onrender.com';

  Future<Map<String, dynamic>> generarFactura() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Usuario no autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/Facturacion/generar'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al generar factura: ${response.statusCode}');
    }
  }
}