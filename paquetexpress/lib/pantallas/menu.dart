import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../DeliveryRoute.dart';
import 'paquetes.dart';
import 'Rutas.dart';
import '../pantallas/configuración.dart';
// import 'configuracion.dart';

class Inicio extends StatefulWidget {
  final int transportistaId;
  const Inicio({super.key, required this.transportistaId});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _seleccionado = 0;

  List<Widget> _getPantallas(BuildContext context) {
    final delivery = Provider.of<DeliveryProvider>(context);

    return [
      Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromARGB(255, 45, 125, 174),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/imagen2.png', width: 200, height: 200),
            const SizedBox(height: 16),
            const Text(
              " Donde la eficiencia encuentra la puntualidad.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      delivery.hasActiveRoute
          ? RutaPantalla(
              paquete: delivery.activeRoute!,
              transportistaId: widget.transportistaId,
            )
          : Container(
              color: Colors.blue.shade800,
              child: const Center(
                child: Text(
                  "No hay entrega activa",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      PaquetesSinEntregar(
        transportistaId: widget.transportistaId,
        onRecargar: () => setState(() {}),
      ),
      ConfiguracionScreen(
        transportistaId: widget.transportistaId,
      ), // Aquí usas la nueva pantalla
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // MENU INFERIOR
      body: _getPantallas(context)[_seleccionado],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seleccionado,
        onTap: (i) => setState(() => _seleccionado = i),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color.fromARGB(255, 203, 238, 243),
        backgroundColor: Color.fromARGB(255, 29, 53, 87),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: "Ruta"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Paquetes",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Config"),
        ],
      ),
    );
  }
}
