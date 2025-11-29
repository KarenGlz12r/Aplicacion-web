import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryProvider extends ChangeNotifier {
  Map<String, dynamic>? _activeRoute;

  Map<String, dynamic>? get activeRoute => _activeRoute;

  bool get hasActiveRoute => _activeRoute != null;

  final String apiUrl = "http://localhost:8000";

  // ------------------------------
  //  Iniciar ruta
  // ------------------------------
  void startRoute(Map<String, dynamic> paquete) {
    _activeRoute = paquete;
    notifyListeners();
  }

  // ------------------------------
  //  Finalizar ruta (solo local)
  // ------------------------------
  void finishRoute() {
    _activeRoute = null;
    notifyListeners();
  }

  //   Future<bool> finalizarEntrega(int idPaquete) async {
  //     try {
  //       final url = Uri.parse("$apiUrl/paquetes/$idPaquete/estado");

  //       final response = await http.put(
  //         url,
  //         headers: {"Content-Type": "application/json"},
  //         body: jsonEncode({"estado": "Entregado"}),
  //       );

  //       if (response.statusCode == 200) {
  //         // Limpia la ruta activa
  //         _activeRoute = null;
  //         notifyListeners();
  //         return true;
  //       } else {
  //         debugPrint("Error API: ${response.body}");
  //         return false;
  //       }
  //     } catch (e) {
  //       debugPrint("Error al conectar con API: $e");
  //       return false;
  //     }
  //   }
}
