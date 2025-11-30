import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/agendamiento.dart';
import '../services/auth_service.dart';

class AgendamientoService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Agendamiento>> obtenerAgendamientos() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.agendamientos}';
      
      print('🔍 Intentando conectar a: $url');
      print('📋 Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response Body (primeros 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Agendamiento.fromJson(json)).toList();
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
      }
    } on FormatException catch (e) {
      print('❌ Error de formato JSON: $e');
      throw Exception('Error al procesar la respuesta de la API (formato JSON inválido): $e');
    } on http.ClientException catch (e) {
      print('❌ Error de cliente HTTP: $e');
      String errorMessage = 'Error de conexión HTTP: $e';
      
      // Detectar error de CORS
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('CORS') ||
          e.toString().contains('Access-Control-Allow-Origin')) {
        errorMessage = 'Error de CORS: El servidor no permite peticiones desde el navegador. '
            'Solución: Ejecuta la app en un dispositivo móvil o usa Chrome con CORS deshabilitado para desarrollo. '
            'Ver CORS_SOLUTION.md para más detalles.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Error general: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      
      String errorMessage = 'Error: $e';
      
      // Detectar error de CORS
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('CORS') ||
          e.toString().contains('Access-Control-Allow-Origin')) {
        errorMessage = 'Error de CORS: El servidor no permite peticiones desde el navegador. '
            'Solución: Ejecuta la app en un dispositivo móvil o usa Chrome con CORS deshabilitado para desarrollo. '
            'Ver CORS_SOLUTION.md para más detalles.';
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<Agendamiento> obtenerAgendamientoPorId(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Agendamiento> crearAgendamiento(Agendamiento agendamiento) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}'),
        headers: headers,
        body: jsonEncode(agendamiento.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Agendamiento> actualizarAgendamiento(Agendamiento agendamiento) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/${agendamiento.id}'),
        headers: headers,
        body: jsonEncode(agendamiento.toJson()),
      );

      if (response.statusCode == 200) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        return agendamiento;
      } else {
        throw Exception('Error al actualizar agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> eliminarAgendamiento(int id) async {
    try {
      final headers = await _getHeaders();
      
      // Log the deletion for debugging
      print('Eliminando agendamiento $id');
      
      // Send DELETE request to the server
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el agendamiento: ${response.statusCode}');
      }
      
      print('Agendamiento $id eliminado exitosamente');
      
    } catch (e) {
      print('Error en eliminarAgendamiento: $e');
      throw Exception('Error al eliminar agendamiento: $e');
    }
  }
}

