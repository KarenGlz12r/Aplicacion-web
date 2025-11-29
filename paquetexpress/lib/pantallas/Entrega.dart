import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../DeliveryRoute.dart';
import 'Rutas.dart';

class Entrega extends StatefulWidget {
  final int id_paquete;
  const Entrega({super.key, required this.id_paquete});

  // CREAMOS EL ESTADO
  @override
  State<Entrega> createState() => _EntregaState();
}

class _EntregaState extends State<Entrega> {
  @override
  Widget build(BuildContext context) {
    return;
  }
}
