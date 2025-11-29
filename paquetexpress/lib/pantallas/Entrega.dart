import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:paquetexpress/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// Importa para verificar si es web
import 'package:flutter/foundation.dart' show kIsWeb;

class Entrega extends StatefulWidget {
  final int id_paquete;
  String? destinatario;
  Entrega({super.key, required this.id_paquete, this.destinatario});

  @override
  State<Entrega> createState() => _EntregaState();
}

class _EntregaState extends State<Entrega> {
  bool isLoading = false;
  File? fotoSeleccionada;
  Uint8List? _imageBytes; // Para almacenar los bytes de la imagen en web
  final ImagePicker _picker = ImagePicker();
  int? repartidor;

  // Método para seleccionar foto desde archivos
  Future<void> seleccionarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 700,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (foto != null) {
        if (kIsWeb) {
          // En web, leemos los bytes de la imagen
          final bytes = await foto.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            // En web también podemos mantener la referencia al File si es necesario
            fotoSeleccionada = File(foto.path);
          });
        } else {
          // En móvil, usamos File normalmente
          setState(() {
            fotoSeleccionada = File(foto.path);
          });
        }
      }
    } catch (e) {
      print("Error al seleccionar la foto: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al seleccionar la foto")));
    }
  }

  // Widget para mostrar la imagen que funciona tanto en web como en móvil
  Widget _buildImagePreview() {
    if (kIsWeb && _imageBytes != null) {
      // En web: usar Image.memory con los bytes
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (fotoSeleccionada != null) {
      // En móvil: usar Image.file
      return Image.file(fotoSeleccionada!, fit: BoxFit.cover);
    } else {
      // Texto para  cuando no hay imagen
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 50, color: Colors.grey),
          Text("No hay imagen seleccionada"),
        ],
      );
    }
  }

  Future<void> finalizarEntrega() async {
    // Validamos que exista una foto
    if (fotoSeleccionada == null && _imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SELECCIONA UNA FOTO PRIMERO")));
      return;
    }

    // Obtenemos el Id del repartidor
    final authprovider = Provider.of<Authprovider>(context, listen: false);
    repartidor = authprovider.getTransportista();

    if (repartidor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No hay ID, tiempo de llorar")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Obtenemos la ubicación actual
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print("Ubicación actual: ${pos.latitude}, ${pos.longitude}");
      print("Id del paquete: ${widget.id_paquete}");
      print("Id repartidor: $repartidor");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/entrega/'),
      );

      // Agregamos los campos como Form-data
      request.fields['id_rep'] = repartidor!.toString();
      request.fields['id_pq'] = widget.id_paquete.toString();
      request.fields['latitud'] = pos.latitude.toString();
      request.fields['longitud'] = pos.longitude.toString();

      // Manejo diferente para web y móvil al agregar la imagen
      if (kIsWeb && _imageBytes != null) {
        // En web: usar MultipartFile.fromBytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imageBytes!,
            filename: 'entrega_${widget.id_paquete}.jpg',
          ),
        );
      } else if (fotoSeleccionada != null) {
        // En móvil: usar MultipartFile.fromPath
        request.files.add(
          await http.MultipartFile.fromPath('file', fotoSeleccionada!.path),
        );
      }

      print("Enviando peticion a la API");

      // ENVIAMOS LA PETICIÓN
      var response = await request.send();
      String body = await response.stream.bytesToString();

      print("Respuesta recibida - estado: ${response.statusCode}");
      print("Body: ${body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Entrega realizada")));
        Navigator.pop(context);
      } else {
        final error = json.decode(body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${error['detail'] ?? 'Error desconocido'}"),
          ),
        );
      }
    } catch (e) {
      print("Error en la entrega: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error en la conexión: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 102, 155, 188),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 29, 53, 87),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping,
              color: Color.fromARGB(255, 237, 246, 249),
              size: 40,
            ),
            SizedBox(width: 10),
            Text(
              "PAQUEXPRESS",
              style: GoogleFonts.rajdhani(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Finalizar entrega",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Paquete ID: ${widget.id_paquete}",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Evidencia de la entrega",
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            SizedBox(height: 10),

            // Container para la imagen preview
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildImagePreview(),
            ),

            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: seleccionarFoto,
                    icon: Icon(Icons.photo_library),
                    label: Text("Seleccionar Foto"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 34, 34, 59),
                      foregroundColor: Color.fromARGB(255, 74, 78, 105),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: finalizarEntrega,
                    child: Text("Finalizar Entrega"),
                  ),
          ],
        ),
      ),
    );
  }
}
