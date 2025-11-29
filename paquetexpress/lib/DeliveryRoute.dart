import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryProvider extends ChangeNotifier {
  Map<String, dynamic>? _activeRoute;

  Map<String, dynamic>? get activeRoute => _activeRoute;

  bool get hasActiveRoute => _activeRoute != null;

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

  // Metodo para ver el estado del paquete

  Future<bool> verificar() async {
    if (_activeRoute == null) return false;

    //
    try {
      final url = Uri.parse(
        'http://localhost:8000/paquetes/propios/${_activeRoute!['id_r]']}',
      );
      final response = await http.get(url);

      if (response == 200) {
        final paquetes = json.decode(response.body);
        final actual = paquetes.firstWhere(
          (p) => p['id_pq'] == _activeRoute!['id_pq'],
          orElse: () => null,
        );
        //  Sino encuetra ek paquete o esta entregado
        if (actual == null || actual['estado'] == 'Entregadp') {
          _activeRoute = null;
          notifyListeners();
          return false;
        }
        return true;
      }
    } catch (e) {
      print("Error encontrando el estado: $e");
    }
    return false;
  }
}
