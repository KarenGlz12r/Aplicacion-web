import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../DeliveryRoute.dart';
import 'Rutas.dart';

// Creamos la clase que sera stateful porque tendra cambios
class PaquetesSinEntregar extends StatefulWidget {
  final int
  transportistaId; // EL ID DEL TRANSPORTISTA, PARA HACER LA BUSQUEDA DE PAQUETES
  final VoidCallback? //PARA
  onRecargar; //Cada tanto recarga la pantalla para mantener actualizada la lista

  const PaquetesSinEntregar({
    super.key,
    required this.transportistaId, //REQUIERE FORZOSAMENTE EL ID DEL TRANSPORTISTA
    this.onRecargar,
  });

  // CREAMOS EL ESTADO
  @override
  State<PaquetesSinEntregar> createState() => _PaquetesSinEntregarState();
}

// CREAMOS LA PANTALLA DEL ESTADO
class _PaquetesSinEntregarState extends State<PaquetesSinEntregar> {
  List<dynamic> paquetes = []; //SE CREA UNA LISTA PARA RECIBIR LOS PAQUETES
  bool cargando = true;
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

  Future<void> obtenerPaquetes({bool silent = false}) async {
    if (!silent) setState(() => cargando = true);

    try {
      final url = Uri.parse(
        "http://localhost:8000/paquetes/propios/${widget.transportistaId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final todosPaquetes = json.decode(response.body);
        // Filtrar solo los paquetes con estado "sin_entregar"
        final pendientes = todosPaquetes
            .where((p) => p["estado"] == "Sin entregar")
            .toList();

        setState(() {
          paquetes = pendientes;
          cargando = false;
        });

        widget.onRecargar?.call();
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      setState(() => cargando = false);
      debugPrint("Error al obtener paquetes: $e");
    }
  }

  void recargar() => obtenerPaquetes();

  @override
  Widget build(BuildContext context) {
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
                      title: Text(
                        p["destinatario"],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        " Colonia: ${p['colonia']}  Calle:${p['calle']}   Número: ${p['numero']}  Codigo postal: ${p['codigo_postal']} ",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 3, 4, 94),
                        ),
                        onPressed: () async {
                          Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          ).startRoute(p);

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RutaPantalla(
                                paquete: p,
                                transportistaId: widget.transportistaId,
                              ),
                            ),
                          );

                          recargar();
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
