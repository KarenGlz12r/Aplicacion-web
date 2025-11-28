import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../DeliveryRoute.dart';

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
    print("🔄 Iniciando RutaPantalla...");
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
        "${widget.paquete['calle']} ${widget.paquete['numero']}, ${widget.paquete['colonia']}";

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

          if (origen != null) {
            _generarRuta();
          } else {
            print(" Origen aún no disponible, esperando GPS...");
          }
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

  Future<void> _generarRuta() async {
    if (origen == null || destino == null) {
      print("⚠️ No se puede generar ruta: origen o destino nulos");
      return;
    }

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${origen!.longitude},${origen!.latitude};"
        "${destino!.longitude},${destino!.latitude}"
        "?geometries=geojson&overview=full";

    print("Generando ruta con OSRM...");
    print(" URL OSRM: $url");

    try {
      final res = await http.get(Uri.parse(url));

      print(" Respuesta OSRM - Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["routes"] != null && data["routes"].isNotEmpty) {
          final route = data["routes"][0];
          final geometry = route["geometry"]["coordinates"];

          rutaCoordenadas = geometry
              .map<LatLng>((c) => LatLng(c[1], c[0]))
              .toList();

          distanciaKm = route["distance"] / 1000;
          duracionSegundos = route["duration"].toInt();

          print("Ruta generada exitosamente");
          print("📏 Distancia: ${distanciaKm.toStringAsFixed(2)} km");
          print("⏱️ Duración: $duracionSegundos segundos");

          setState(() {});
        } else {
          print(" OSRM: No se pudo generar la ruta - respuesta vacía");
        }
      } else {
        print(" Error HTTP OSRM: ${res.statusCode}");
      }
    } catch (e) {
      print(" Error ruta OSRM: $e");
      debugPrint("Error ruta OSRM: $e");
    }
  }

  String formatoTiempo(int s) {
    int h = s ~/ 3600;
    int m = (s % 3600) ~/ 60;
    if (h > 0) return "${h}h ${m}m";
    return "$m min";
  }

  @override
  Widget build(BuildContext context) {
    print(" Reconstruyendo widget...");
    print(" Origen: $origen");
    print(" Destino: $destino");
    print(" Ruta coordenadas: ${rutaCoordenadas.length} puntos");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(184, 60, 63, 255),
        title: Text(
          "Entrega: ${widget.paquete['nombre']}",
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
                print("🗺️ Mapa listo y cargado");
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

              // ORIGEN
              if (origen != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: origen!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
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
                        Icons.flag,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              // RUTA
              if (rutaCoordenadas.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: rutaCoordenadas,
                      color: const Color.fromARGB(255, 218, 0, 0),
                      strokeWidth: 4,
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
                        "Calculando ruta...",
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

            if (distanciaKm > 0)
              Text(
                "Distancia: ${distanciaKm.toStringAsFixed(2)} km",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            if (duracionSegundos > 0)
              Text(
                "Tiempo estimado: ${formatoTiempo(duracionSegundos)}",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () async {
                print(
                  " Finalizando entrega para paquete: ${widget.paquete["id_paq"]}",
                );
                bool ok = await Provider.of<DeliveryProvider>(
                  context,
                  listen: false,
                ).finalizarEntrega(widget.paquete["id_paq"]);

                if (ok) {
                  print("Entrega finalizada exitosamente");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Paquete entregado correctamente"),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  print(" Error al finalizar entrega");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al completar entrega")),
                  );
                }
              },
              child: const Text("Finalizar entrega"),
            ),
          ],
        ),
      ),
    );
  }
}
