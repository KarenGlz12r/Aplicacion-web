// Import para temporizadores (Timer) usados en recarga periódica
import 'dart:async';

// Import para decodificar el cuerpo JSON de las respuestas HTTP
import 'dart:convert';
import 'package:flutter/material.dart';
// Import de Google Fonts para tipografías estilizadas en la UI
import 'package:google_fonts/google_fonts.dart';
// Cliente HTTP para realizar peticiones al backend
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
// Provider local que maneja rutas/entregas en la app (startRoute, etc.)
import '../DeliveryRoute.dart';
import 'Rutas.dart';

// Widget con estado que muestra la lista de paquetes asignados al transportista
// Se usa stateful porque la lista se actualiza periódicamente y al regresar de rutas
class PaquetesSinEntregar extends StatefulWidget {
  // ID del transportista para filtrar los paquetes que le pertenecen
  final int
  transportistaId; // EL ID DEL TRANSPORTISTA, PARA HACER LA BUSQUEDA DE PAQUETES

  // Callback opcional que se puede llamar cuando la lista se recarga (útil para padres)
  final VoidCallback?
  onRecargar; // Cada tanto recarga la pantalla para mantener actualizada la lista

  const PaquetesSinEntregar({
    super.key,
    required this.transportistaId, //REQUIERE FORZOSAMENTE EL ID DEL TRANSPORTISTA
    this.onRecargar,
  });

  // CREAMOS EL ESTADO
  @override
  State<PaquetesSinEntregar> createState() => _PaquetesSinEntregarState();
}

// Estado privado del widget: contiene la lista de paquetes y control de carga/tiempo
class _PaquetesSinEntregarState extends State<PaquetesSinEntregar> {
  // Lista dinámica que almacenará los paquetes obtenidos del backend
  List<dynamic> paquetes = []; // SE CREA UNA LISTA PARA RECIBIR LOS PAQUETES

  // Flag para mostrar indicador de carga mientras se obtienen datos
  bool cargando = true;

  // Timer para recarga periódica automática (cada X segundos)
  Timer? tiempo;

  @override
  void initState() {
    super.initState();
    obtenerPaquetes();
    actualizar();
  }

  @override
  void dispose() {
    tiempo?.cancel();
    super.dispose();
  }

  void actualizar() {
    tiempo = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        obtenerPaquetes(silent: true);
      }
    });
  }

  // Método que consulta al backend los paquetes asignados al transportista
  // Si 'silent' es true no muestra el indicador de carga para no alterar la UI
  Future<void> obtenerPaquetes({bool silent = false}) async {
    // Si no es silent, activamos el indicador de carga
    if (!silent) setState(() => cargando = true);

    try {
      // Armamos la URL que trae los paquetes del transportista concreto
      final url = Uri.parse(
        "http://localhost:8000/paquetes/propios/${widget.transportistaId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Decodificamos el JSON recibido en una lista/objeto Dart
        final todosPaquetes = json.decode(response.body);

        // Filtrar solo los paquetes cuyo campo estado sea "Sin entregar"
        final pendientes = todosPaquetes
            .where((p) => p["estado"] == "Sin entregar")
            .toList();

        // Actualizar el estado con los paquetes filtrados y ocultar el loader
        setState(() {
          paquetes = pendientes;
          cargando = false;
        });

        widget.onRecargar?.call();
      } else {
        // En caso de error en la respuesta, simplemente dejamos de mostrar carga
        setState(() => cargando = false);
      }
    } catch (e) {
      // Manejo de excepciones de red u otras fallas
      setState(() => cargando = false);
      debugPrint("Error al obtener paquetes: $e");
    }
  }

  void recargar() => obtenerPaquetes();

  @override
  Widget build(BuildContext context) {
    // UI principal: fondo con color corporativo
    return Container(
      color: const Color.fromARGB(255, 0, 61, 105),
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : paquetes.isEmpty
          ? const Center(
              child: Text(
                "No hay paquetes por entregar",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paquetes.length,
              itemBuilder: (_, index) {
                final p = paquetes[index];
                // Cada paquete se representa como una Card con título, subtítulo y acción
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(255, 255, 255, 1),
                          Color.fromARGB(255, 255, 255, 255),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      // Nombre del destinatario como título principal
                      title: Text(
                        p["destinatario"],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Dirección/ubicación del paquete en el subtítulo
                      subtitle: Text(
                        " Colonia: ${p['colonia']}  Calle:${p['calle']}   Número: ${p['numero']}  Codigo postal: ${p['codigo_postal']} ",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 3, 4, 94),
                        ),
                        onPressed: () async {
                          // Al presionar iniciar entrega: avisamos al DeliveryProvider
                          // que empecemos la ruta con este paquete y navegamos a la pantalla Ruta
                          Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          ).startRoute(p);

                          // Navegar a la pantalla de la ruta para gestionar la entrega
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RutaPantalla(
                                paquete: p,
                                transportistaId: widget.transportistaId,
                              ),
                            ),
                          );

                          // Al volver de la pantalla de ruta, recargamos la lista
                          recargar();
                          Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          ).finishRoute();
                        },
                        child: Text(
                          "Iniciar entrega",
                          style: GoogleFonts.poppins(
                            color: Color.fromARGB(255, 222, 219, 210),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/*
Diccionario / Resumen (en español):

- PaquetesSinEntregar: Widget stateful que lista los paquetes asignados a un transportista.
- transportistaId: Id requerido para filtrar las rutas/paquetes del transportista.
- onRecargar: Callback opcional que notifica al widget padre cuando se actualiza la lista.
- paquetes: Lista con los objetos (Map) que representan cada paquete.
- cargando: Flag que activa/desactiva el indicador de carga.
- tiempo: Timer utilizado para recargar la lista automáticamente cada X segundos.
- obtenerPaquetes(): Función asíncrona que hace GET a /paquetes/propios/{transportistaId} y filtra por estado "Sin entregar".
- recargar(): Wrapper que llama a obtenerPaquetes() y puede usarse para forzar refresco.
- startRoute(p): Método del DeliveryProvider que inicia la lógica de entrega (definido en DeliveryRoute.dart).
- RutaPantalla: Pantalla que se abre para gestionar la ruta/entrega del paquete seleccionado.

Notas:
- Asegúrate de que el backend esté accesible en la URL configurada (http://localhost:8000), especialmente si usas emulador/dispositivo.
- La recarga automática usa Timer.periodic de 10 segundos; puedes ajustar la frecuencia si fuera necesario.
*/
