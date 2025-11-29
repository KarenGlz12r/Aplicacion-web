// Import core de Flutter para widgets y material design
import 'package:flutter/material.dart';
// Google Fonts para tipografías más agradables (Poppins, etc.)
import 'package:google_fonts/google_fonts.dart';
// Provider: para leer providers de estado como DeliveryProvider
import 'package:provider/provider.dart';
// Geolocator: para obtener la ubicación GPS del dispositivo
import 'package:geolocator/geolocator.dart';
// flutter_map: librería para mostrar mapas (Leaflet for Flutter)
import 'package:flutter_map/flutter_map.dart';
// LatLng y utilidades para representar coordenadas geográficas
import 'package:latlong2/latlong.dart';
// Cliente HTTP para llamadas REST (usado para geocoding y pruebas de conectividad)
import 'package:http/http.dart' as http;
// Utilidades JSON (decoding responses)
import 'dart:convert';
import 'dart:async';
// Provider/local que maneja la lógica de ruteo/entrega (startRoute, etc.)
import '../DeliveryRoute.dart';
// Pantalla para gestionar la entrega de un paquete (navegación final)
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
  // Controlador del mapa para manipular centro/zoom desde el código
  MapController mapController = MapController();

  // Coordenadas del punto de origen (posición actual del dispositivo)
  LatLng? origen;

  // Coordenadas del destino (dirección del paquete geocodificada)
  LatLng? destino;

  // Lista de coordenadas que forman la ruta entre origen y destino
  List<LatLng> rutaCoordenadas = [];

  // Distancia aproximada (km) y duración en segundos de la ruta (si se calcula)
  double distanciaKm = 0;
  int duracionSegundos = 0;

  // Flags para permisos GPS y si el mapa ya terminó de cargarse
  bool _gpsPermitido = false;
  bool _mapaCargado = false;

  @override
  void initState() {
    super.initState();
    // Mensaje de depuración y comienzo de comprobaciones importantes
    print(" Iniciando Ruta...");

    // Verificar (y pedir si hace falta) permisos de ubicación
    _verificarPermisosUbicacion();

    // Probar conexión con servidores de mapas (para detectar problemas de red)
    _probarConexionMapas(); // Probar conexión

    // Veririfacion por tiempo

    Timer.periodic(Duration(seconds: 20), (timer) {
      if (mounted) {
        verificarEstado();
      } else {
        timer.cancel();
      }
    });
  }

  // Verificar qjue el paquete no haya sido entregado

  Future<void> verificarEstado() async {
    try {
      final url = Uri.parse(
        "http://localhost:8000/paquetes/propios/${widget.transportistaId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final paquetes = json.decode(response.body);
        final actual = paquetes.firstWhere(
          (p) => p['id_pq'] == widget.paquete['id_pq'],
          orElse: () => null,
        );

        // Si ya esta entregado
        if (actual == null || actual['estado'] == 'Entregado') {
          if (mounted) {
            // limpiar la ruta
            Provider.of<DeliveryProvider>(context, listen: false).finishRoute();
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      print("Error verificando el esgtado : ${e}");
    }
  }

  // Intenta descargar tiles de dos servidores de mapas para asegurar conectividad
  Future<void> _probarConexionMapas() async {
    try {
      print(" Probando conexión con servidores de mapas...");

      // Probar acceso a OpenStreetMap (tile demo)
      final response = await http.get(
        Uri.parse('https://tile.openstreetmap.org/14/8192/8192.png'),
      );
      print(" Conexión OpenStreetMap: ${response.statusCode}");

      // Probar acceso a CartoDB basemap
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

  // Comprueba permisos de ubicación y solicita al usuario si es necesario
  Future<void> _verificarPermisosUbicacion() async {
    try {
      print(" Verificando permisos de ubicación...");

      // Comprueba el permiso actual del sistema para usar localización
      LocationPermission permission = await Geolocator.checkPermission();
      print(" Permiso actual: $permission");

      // Si está denegado, solicitamos permiso de uso mientras la app está en foreground
      if (permission == LocationPermission.denied) {
        print(" Permiso denegado, solicitando...");
        permission = await Geolocator.requestPermission();
        print(" Nuevo permiso: $permission");
      }

      // Si el usuario denegó permanentemente, mostramos diálogo para abrir ajustes
      if (permission == LocationPermission.deniedForever) {
        print(" Permiso denegado permanentemente");
        _mostrarDialogoPermisos();
        return;
      }

      // Si están concedidos, marcamos _gpsPermitido y obtenemos posición actual
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print(" Permisos concedidos, obteniendo ubicación...");
        setState(() {
          _gpsPermitido = true;
        });
        // Obtener posición y convertir la dirección del paquete a coordenadas
        await _obtenerPosicionActual();
        _convertirDireccionACoordenadas();
      } else {
        print(" Permiso no concedido: $permission");
      }
    } catch (e) {
      print(" Error en verificación de permisos: $e");
    }
  }

  // Muestra un diálogo explicando por qué se necesitan permisos y ofrece abrir configuración
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
            // Botón cancelar: simplemente cierra el diálogo
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            // Botón para abrir la configuración de la app (permite al usuario habilitar permisos)
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

  // Obtiene la posición GPS actual y la guarda en 'origen'
  Future<void> _obtenerPosicionActual() async {
    try {
      // Si no se concedieron permisos, no intentamos obtener la posición
      if (!_gpsPermitido) {
        print(" GPS no permitido, saltando obtención de ubicación");
        return;
      }

      print(" Obteniendo posición GPS...");
      // Pide al dispositivo la posición actual con precisión alta
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(" GPS obtenido: ${p.latitude}, ${p.longitude}");
      // Guardamos la ubicación en 'origen' y forzamos reconstrucción
      setState(() {
        origen = LatLng(p.latitude, p.longitude);
      });
    } catch (e) {
      // Manejo de errores GPS
      print(" Error GPS: $e");
      debugPrint("Error GPS: $e");
    }
  }

  // Geocodifica la dirección del paquete usando Nominatim (OpenStreetMap)
  Future<void> _convertirDireccionACoordenadas() async {
    // Construye una cadena legible con la dirección del paquete
    final direccion =
        "${widget.paquete['calle']} ${widget.paquete['numero']}, ${widget.paquete['colonia']},${widget.paquete['codigo_postal']}";

    // Endpoint de Nominatim para convertir dirección a coordenadas (geocoding)
    final url =
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(direccion)}";

    print(" Geocodificando dirección: $direccion");
    print(" URL Nominatim: $url");

    try {
      // Realizamos la llamada HTTP a Nominatim (recomendado incluir User-Agent)
      final res = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Flutter App"},
      );

      print(" Respuesta Nominatim - Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        // Si la respuesta contiene resultados, tomamos la primera ubicación encontrada
        if (data.isNotEmpty) {
          print(" Dirección geocodificada exitosamente");
          destino = LatLng(
            double.parse(data[0]['lat']),
            double.parse(data[0]['lon']),
          );
          print(
            " Destino coordenadas: ${destino!.latitude}, ${destino!.longitude}",
          );

          // Actualizamos la UI para mostrar el marcador de destino
          setState(() {});
        } else {
          print(" Nominatim: No se encontraron resultados para la dirección");
        }
      } else {
        print(" Error HTTP Nominatim: ${res.statusCode}");
      }
    } catch (e) {
      // Errores relacionados con la petición de geocoding
      print(" Error geocodificación Nominatim: $e");
      debugPrint("Error geocodificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logs para depuración mostrando origen/destino actuales
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
      // Cuerpo principal: mapa y capa de carga superpuesta
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              // Centro inicial: si no hay origen, usar coordenada por defecto
              initialCenter: origen ?? LatLng(20.650609, -100.406351),
              initialZoom: 10, // Zoom más abierto para ver la ruta larga
              onMapReady: () {
                // Marca que el mapa ya terminó de cargarse
                print("Mapa listo y cargado");
                setState(() {
                  _mapaCargado = true;
                });
              },
            ),
            children: [
              // Capa de tiles que dibuja el mapa base (Carto Voyager)
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.appmovil.delivery',
              ),
              // DESTINO
              // Si ya se tiene la ubicación del destino, dibujar marcador
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
          // Mostrar un overlay de carga mientras mapa/origen/destino no estén listos
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

      // Panel inferior (bottom sheet) con detalles del paquete y acción final
      bottomSheet: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar advertencia si no tenemos permisos de ubicación
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
            // Leyenda que explica el marcador mostrado en el mapa
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.person_pin_circle, color: Colors.red, size: 20),
                SizedBox(width: 5),
                Text('Dirección de destino: '),
              ],
            ),
            SizedBox(height: 10),
            // Muestra la dirección del paquete en texto legible
            Text(
              " Colonia: ${widget.paquete['colonia']}, Calle:  ${widget.paquete['calle']}, Número: ${widget.paquete['numero']}, Codigo postal: ${widget.paquete['codigo_postal']}",
            ),
            SizedBox(height: 15),
            // Botón para finalizar la entrega: navega a la pantalla de Entrega
            ElevatedButton(
              onPressed: () {
                print("Destinatario: ${widget.paquete['destinatario']}");
                Provider.of<DeliveryProvider>(
                  context,
                  listen: false,
                ).finishRoute();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Entrega(
                      id_paquete: widget.paquete['id_pq'],
                      destinatario: widget.paquete['destinatario'],
                    ),
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

/*
Diccionario / Resumen (en español):

- RutaPantalla: Widget que muestra el mapa y la ruta para un paquete específico.
- paquete: Mapa con los datos del paquete (calle, número, colonia, destinatario, id_pq, etc.).
- transportistaId: Id del usuario/transportista que realiza la entrega.
- origen: Coordenadas actuales del conductor (obtenidas por GPS).
- destino: Coordenadas del destino geocodificadas desde la dirección (Nominatim/OpenStreetMap).
- _probarConexionMapas(): Verifica la conexión a servidores de tiles (OSM y Carto) para detectar fallos de red.
- _verificarPermisosUbicacion(): Gestiona permisos GPS y solicita al usuario si hace falta.
- _obtenerPosicionActual(): Recupera la localización del dispositivo con Geolocator y la guarda en 'origen'.
- _convertirDireccionACoordenadas(): Llama a Nominatim para convertir la dirección a lat/lon y guarda en 'destino'.
- _mapaCargado: Flag que indica si el widget de mapa ya terminó de cargar.
- Bottom sheet: Muestra dirección, leyenda y botón para finalizar la entrega (navega a `Entrega`).

Notas:
- La app usa 'http://localhost' para pruebas en desarrollo — recuerda que en emuladores/dispositivos reales debes usar la IP correcta del servidor.
- Si Nominatim no encuentra resultados, el marcador de destino no se mostrará y el usuario verá "Calculando destino..." hasta que se resuelva.
*/
