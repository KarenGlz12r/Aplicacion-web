// AQUI ES PURO ADMIN (CREAR PAQUETES Y REGISTRAR USUARIOS)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paquetexpress/pantallas/menu.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import '../AuthProvider.dart';
import './inicioSesion.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanel extends StatefulWidget {
  int? transportistaId;
  AdminPanel({super.key, this.transportistaId});

  @override
  State<AdminPanel> createState() => AdminPanelState();
}

class AdminPanelState extends State<AdminPanel> {
  int indiceSele = 0;

  // Lista de pantallas para navegar
  late final List<Widget> pantallas = [
    const Registro(),
    const TransportistaLista(),
    ConfiguracionScreen(transportistaId: widget.transportistaId ?? 0),
    CrearPaquete(),
  ];

  // Titulos

  final List<String> titulos = [
    'Alta repartidores',
    'Lista de Transportistas',
    'Configuración',
    'Crear Paquetes',
  ];

  // Para camv=biar de pantalla
  void cambiarPantalla(int indice) {
    setState(() {
      indiceSele = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 34, 34, 59),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_shipping,
                color: Color.fromARGB(255, 237, 246, 249),
                size: 40,
              ),
              const SizedBox(width: 15),
              Text(
                "PAQUEXPRESS",
                style: GoogleFonts.rajdhani(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
      ),

      body: pantallas[indiceSele],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceSele,
        onTap: cambiarPantalla,
        backgroundColor: const Color.fromARGB(255, 29, 53, 87),
        selectedItemColor: const Color.fromARGB(255, 18, 54, 66),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: "Registrar Repartidores",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Repartidores",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Configuración",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gif_box_sharp),
            label: "Paquetes",
          ),
        ],
      ),
    );
  }
}

// Clase de registro de transportistas

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => RegistroState();
}

class RegistroState extends State<Registro> {
  // Variables

  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final contraController = TextEditingController();
  final confirController = TextEditingController();

  bool ocultar = true;

  // Creamos el metodo para crear un repartidor

  Future<void> crearRepartidor() async {
    if (contraController.text != confirController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }
    if (nombreController.text.isEmpty ||
        correoController.text.isEmpty ||
        contraController.text.isEmpty ||
        confirController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }

    // Si todo esta bien

    final url = Uri.parse('http://localhost:8000/transportista/crear');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nombre": nombreController.text,
        "correo": correoController.text,
        "password": contraController.text,
      }),
    );

    print("body; ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registro Exitoso")));

      nombreController.clear();
      correoController.clear();
      confirController.clear();
      contraController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR AL REGISTRAR (PROCEDE A LLORAR)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 102, 155, 188),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(10),
            width: double.infinity,
            child: Card(
              elevation: 7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Registro de repartidor",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 29, 53, 87),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Ingresa el nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(
                        labelText: 'Ingresa el correo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: contraController,
                      obscureText: ocultar,
                      decoration: InputDecoration(
                        labelText: 'Ingresa la contraseña:',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultar
                                ? Icons.visibility_off_outlined
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultar = !ocultar;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: confirController,
                      decoration: const InputDecoration(
                        labelText: 'Confirma la contraseña:',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.password),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: crearRepartidor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 29, 53, 87),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text(" Regisrar Repartidor"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransportistaLista extends StatefulWidget {
  final VoidCallback? onRecargar;

  const TransportistaLista({super.key, this.onRecargar});

  @override
  State<TransportistaLista> createState() => TransportistaState();
}

class TransportistaState extends State<TransportistaLista> {
  // Creamos una lista

  List<dynamic> transportistas = [];
  bool cargando = true;
  Timer? tiempo; // para recargar cada cierto tiempo

  @override
  void initState() {
    super.initState();
    obtenerTransportistas();
    actualizar();
  }

  @override
  void dispose() {
    tiempo?.cancel();
    super.dispose();
  }

  void actualizar() {
    tiempo = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        obtenerTransportistas(silent: true);
      }
    });
  }

  // Obtener transportistas
  Future<void> obtenerTransportistas({bool silent = false}) async {
    if (!silent)
      setState(() {
        cargando = true;
      });

    try {
      final url = Uri.parse('http://localhost:8000/transportistas/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final listaTra = json.decode(response.body);

        setState(() {
          transportistas = listaTra;
          cargando = false;
        });

        widget.onRecargar?.call();
        print("Transportistas obtenidos: ${transportistas.length}");
      } else {
        setState(() {
          cargando = false;
          print("Error: ${response.statusCode}");
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
      });
    }
  }

  void recargar() => obtenerTransportistas();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 102, 155, 188),
      child: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : transportistas.isEmpty
          ? const Center(
              child: Text(
                "No hay transportistas registrados",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => obtenerTransportistas(),
              backgroundColor: const Color.fromARGB(255, 102, 155, 188),
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: transportistas.length,
                itemBuilder: (_, index) {
                  final transportista = transportistas[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(255, 255, 255, 1),
                            Color.fromARGB(255, 245, 245, 245),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            transportista['r_nomC'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          transportista['r_nomC'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color.fromARGB(255, 29, 53, 87),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email: ${transportista['r_correo']}",
                              style: GoogleFonts.poppins(fontSize: 15),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "ID: ${transportista['id_r']}",
                              style: GoogleFonts.poppins(fontSize: 15),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              29,
                              53,
                              87,
                            ),
                          ),
                          onPressed: () {
                            detallesTransportistas(context, transportista);
                          },

                          child: Text(
                            "Ver detalles",
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 222, 219, 210),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

void detallesTransportistas(
  BuildContext context,
  Map<String, dynamic> transportista,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Detalles del Transportista",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 29, 53, 87),
          ),
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ID: ${transportista['id_r']?.toString()}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Nombre: ${transportista['r_nomC']}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Correo: ${transportista['r_correo']}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Text(
              "Información del transportista",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar"),
          ),
        ],
      );
    },
  );
}

class CrearPaquete extends StatefulWidget {
  const CrearPaquete({super.key});

  @override
  State<CrearPaquete> createState() => CrearPaqueteState();
}

class CrearPaqueteState extends State<CrearPaquete> {
  // Hacemos una lista, para nuestro select

  List<dynamic> transportistas = [];
  bool cargando = true; //Para que se vea bonito
  int? transporSele;
  String? NombreTrans;

  // Controladores del formulario

  final destinatarioController = TextEditingController();
  final coloniaController = TextEditingController();
  final calleController = TextEditingController();
  final numeroController = TextEditingController();
  final codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    obtenerTransportistas();
  }

  Future<void> obtenerTransportistas() async {
    setState(() {
      cargando = true;
    });

    try {
      final url = Uri.parse('http://localhost:8000/transportistas/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final listaTra = json.decode(response.body);

        setState(() {
          transportistas = listaTra;
          cargando = false;
        });

        print("Transportistas obtenidos: ${transportistas.length}");
      } else {
        setState(() {
          cargando = false;
          print("Error: ${response.statusCode}");
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
      });
    }
  }

  // Crear Paquete

  Future<void> CrearPaquete() async {
    if (transporSele == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un transportista')),
      );
      return;
    }

    if (destinatarioController.text.isEmpty ||
        coloniaController.text.isEmpty ||
        calleController.text.isEmpty ||
        numeroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    try {
      int numero = int.parse(numeroController.text);
      int postal = int.parse(codigoController.text);
      final url = Uri.parse('http://localhost:8000/paquetes/crear/');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "destinatario": destinatarioController.text,
          "colonia": coloniaController.text,
          "calle": calleController.text,
          "numero": numero,
          "codigo_postal": postal,
          "id_rep": transporSele,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Paquete creado')));

        destinatarioController.clear();
        codigoController.clear();
        numeroController.clear();
        coloniaController.clear();
        calleController.clear();
        setState(() {
          transporSele = null;
          NombreTrans = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear el paquete')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  void mostrarTransportistas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                "Seleccionar transportista",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: transportistas.isEmpty
                    ? const Center(
                        child: Text("No hay transportistas disponibles"),
                      )
                    : ListView.builder(
                        itemCount: transportistas.length,
                        itemBuilder: (context, index) {
                          final transportista = transportistas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  29,
                                  53,
                                  87,
                                ),
                                child: Text(
                                  transportista['r_nomC'][0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                transportista['r_nomC'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(transportista['r_correo']),
                              trailing: transporSele == transportista['id_r']
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                setState(() {
                                  transporSele = transportista['id_r'];
                                  NombreTrans = transportista['r_nomC'];
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 102, 155, 188),
      appBar: AppBar(
        title: Text(
          "Crear Nuevo paquete",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 29, 53, 87),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Transportista asignado",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: Text(
                                NombreTrans ?? 'No seleccionado',
                                style: GoogleFonts.poppins(
                                  color: NombreTrans == null
                                      ? Colors.green
                                      : const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              subtitle: Text(
                                transporSele != null
                                    ? 'ID: ${transporSele}'
                                    : 'Selecciona un transportista',
                              ),
                              trailing: const Icon(Icons.arrow_drop_down),
                              onTap: () => mostrarTransportistas(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Formulario para los datos del paquete
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: destinatarioController,
                              decoration: InputDecoration(
                                labelText: 'Destinatario: ',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: coloniaController,
                              decoration: InputDecoration(
                                labelText: 'Colonia: ',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: calleController,
                              decoration: InputDecoration(
                                labelText: 'Calle ',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: numeroController,
                              decoration: InputDecoration(
                                labelText: 'Numero: ',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: codigoController,
                              decoration: InputDecoration(
                                labelText: 'Codigo postal: ',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Boton para crearlo
                            ElevatedButton(
                              onPressed: CrearPaquete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  29,
                                  53,
                                  87,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Crear Paquete",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    destinatarioController.dispose();
    coloniaController.dispose();
    numeroController.dispose();
    calleController.dispose();
    codigoController.dispose();
  }
}

class ConfiguracionScreen extends StatefulWidget {
  final int transportistaId;

  const ConfiguracionScreen({super.key, required this.transportistaId});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  Map<String, dynamic>? transportista;
  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<Authprovider>(context, listen: false);

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $errorMessage')));
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      appBar: AppBar(
        title: Text('Configuración', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 17, 42),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildOptionCard(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    subtitle: 'Configurar alertas y notificaciones',
                    onTap: () {},
                  ),
                  _buildOptionCard(
                    icon: Icons.security,
                    title: 'Privacidad',
                    subtitle: 'Configuración de privacidad y seguridad',
                    onTap: () {},
                  ),
                  _buildOptionCard(
                    icon: Icons.help,
                    title: 'Ayuda y Soporte',
                    subtitle: 'Centro de ayuda y contacto',
                    onTap: () {},
                  ),
                  SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Salir de tu cuenta actual',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        _showLogoutDialog(context, authProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade800),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Authprovider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context, authProvider);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(
    BuildContext context,
    Authprovider authProvider,
  ) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Hacer logout
      await authProvider.logout();

      // Cerrar el diálogo de carga
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Formulario()),
      );

      // El Consumer en main.dart se encargará de mostrar el login automáticamente
    } catch (e) {
      // En caso de error, cerrar el diálogo y mostrar mensaje
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }
}
