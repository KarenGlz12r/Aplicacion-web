import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../DeliveryRoute.dart';
import 'Entrega.dart';

class RutaPantalla extends StatefulWidget {
  final Map<String, dynamic> paquete;
  final int transportistaId;

  const RutaPantalla({
    super.key,
    required this.paquete,
    required this.transportistaId,
  });

  @override
  State<RutaPantalla> createState() => _RutaPantallaState();
}

class _RutaPantallaState extends State<RutaPantalla> {
  MapController mapController = MapController();
  LatLng? origen;
  LatLng? destino;
  List<LatLng> rutaCoordenadas = [];
  double distanciaKm = 0;
  int duracionSegundos = 0;
  bool _gpsPermitido = false;
  bool _mapaCargado = false;

  @override
  void initState() {
    super.initState();
    print(" Iniciando Ruta...");
    _verificarPermisosUbicacion();
    _probarConexionMapas(); // Probar conexión
  }

  // Probar conexión a mapas
  Future<void> _probarConexionMapas() async {
    try {
      print(" Probando conexión con servidores de mapas...");

      // Probar OpenStreetMap
      final response = await http.get(
        Uri.parse('https://tile.openstreetmap.org/14/8192/8192.png'),
      );
      print(" Conexión OpenStreetMap: ${response.statusCode}");

      // Probar CartoDB
      final response2 = await http.get(
        Uri.parse(
          'https://a.basemaps.cartocdn.com/rastertiles/voyager/14/8192/8192.png',
        ),
      );
      print(" Conexión CartoDB: ${response2.statusCode}");
    } catch (e) {
      print(" Error conexión mapas: $e");
    }
  }

  Future<void> _verificarPermisosUbicacion() async {
    try {
      print(" Verificando permisos de ubicación...");

      LocationPermission permission = await Geolocator.checkPermission();
      print(" Permiso actual: $permission");

      if (permission == LocationPermission.denied) {
        print(" Permiso denegado, solicitando...");
        permission = await Geolocator.requestPermission();
        print(" Nuevo permiso: $permission");
      }

      if (permission == LocationPermission.deniedForever) {
        print(" Permiso denegado permanentemente");
        _mostrarDialogoPermisos();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print(" Permisos concedidos, obteniendo ubicación...");
        setState(() {
          _gpsPermitido = true;
        });
        await _obtenerPosicionActual();
        _convertirDireccionACoordenadas();
      } else {
        print(" Permiso no concedido: $permission");
      }
    } catch (e) {
      print(" Error en verificación de permisos: $e");
    }
  }

  void _mostrarDialogoPermisos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permisos de ubicación requeridos"),
          content: Text(
            "Esta aplicación necesita acceso a tu ubicación para mostrar la ruta de entrega. "
            "Por favor, habilita los permisos de ubicación en la configuración de tu dispositivo.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: Text("Abrir configuración"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _obtenerPosicionActual() async {
    try {
      if (!_gpsPermitido) {
        print(" GPS no permitido, saltando obtención de ubicación");
        return;
      }

      print(" Obteniendo posición GPS...");
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(" GPS obtenido: ${p.latitude}, ${p.longitude}");
      setState(() {
        origen = LatLng(p.latitude, p.longitude);
      });
    } catch (e) {
      print(" Error GPS: $e");
      debugPrint("Error GPS: $e");
    }
  }

  Future<void> _convertirDireccionACoordenadas() async {
    final direccion =
        "${widget.paquete['calle']} ${widget.paquete['numero']}, ${widget.paquete['colonia']},${widget.paquete['codigo_postal']}";

    final url =
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(direccion)}";

    print(" Geocodificando dirección: $direccion");
    print(" URL Nominatim: $url");

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Flutter App"},
      );

      print(" Respuesta Nominatim - Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data.isNotEmpty) {
          print(" Dirección geocodificada exitosamente");
          destino = LatLng(
            double.parse(data[0]['lat']),
            double.parse(data[0]['lon']),
          );
          print(
            " Destino coordenadas: ${destino!.latitude}, ${destino!.longitude}",
          );

          setState(() {});
        } else {
          print(" Nominatim: No se encontraron resultados para la dirección");
        }
      } else {
        print(" Error HTTP Nominatim: ${res.statusCode}");
      }
    } catch (e) {
      print(" Error geocodificación Nominatim: $e");
      debugPrint("Error geocodificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print(" Reconstruyendo widget...");
    print(" Origen: $origen");
    print(" Destino: $destino");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(184, 60, 63, 255),
        title: Text(
          "Entrega: ${widget.paquete['destinatario']}",
          style: GoogleFonts.poppins(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: origen ?? LatLng(20.650609, -100.406351),
              initialZoom: 10, // Zoom más abierto para ver la ruta larga
              onMapReady: () {
                print("Mapa listo y cargado");
                setState(() {
                  _mapaCargado = true;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.appmovil.delivery',
              ),
              // DESTINO
              if (destino != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destino!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Color.fromARGB(255, 208, 9, 9),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // INDICADOR DE CARGA
          if (!_mapaCargado || origen == null || destino == null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      "Cargando mapa...",
                      style: TextStyle(color: Colors.white),
                    ),
                    if (origen == null)
                      Text(
                        "Obteniendo ubicación...",
                        style: TextStyle(color: Colors.white),
                      ),
                    if (destino == null)
                      Text(
                        "Calculando destino...",
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // INFORMACIÓN INFERIOR
      bottomSheet: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_gpsPermitido)
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.orange[100],
                child: Text(
                  "Se necesitan permisos de ubicación para mostrar la ruta",
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),

            const SizedBox(height: 15),
            // Leyenda de marcadores
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.person_pin_circle, color: Colors.red, size: 20),
                SizedBox(width: 5),
                Text('Dirección de destino: '),
              ],
            ),
            SizedBox(height: 10),
            Text(
              " Colonia: ${widget.paquete['colonia']}, Calle:  ${widget.paquete['calle']}, Número: ${widget.paquete['numero']}, Codigo postal: ${widget.paquete['codigo_postal']}",
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        Entrega(id_paquete: widget.paquete['id_pq']),
                  ),
                );
              },
              child: const Text("Finalizar entrega"),
            ),
          ],
        ),
      ),
    );
  }
}
