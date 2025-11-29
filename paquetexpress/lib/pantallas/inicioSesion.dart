// Necesario para convertir objetos a JSON y viceversa (jsonEncode/jsonDecode)
import 'dart:convert';
// Import core de Flutter con widgets Material Design
import 'package:flutter/material.dart';
// Librería para usar fuentes de Google (ej. Poppins, Montserrat)
import 'package:google_fonts/google_fonts.dart';
// Cliente HTTP para hacer peticiones al backend
import 'package:http/http.dart' as http;
// Importa el archivo `main.dart` que contiene el wrapper de autenticación
import 'package:paquetexpress/main.dart';
// Import de pantalla relacionada al inicio de administrador (posible navegación)
// Import de la pantalla de admin (usada más abajo como FormularioAdmin).
// Provider para acceder a providers/estados con el patrón Provider
import 'package:provider/provider.dart';
// Provider local que maneja el estado de autenticación y persistencia de sesión
import '../AuthProvider.dart';
// Import de pantallas relacionadas al administrador (formularios / vistas)
// Nota: `Admin.dart` no se usa en este archivo — se elimina para evitar warnings.
import 'AdminInicio.dart';
// import 'registro.dart';

// Widget de estado que representa el formulario principal de inicio de sesión
class Formulario extends StatefulWidget {
  // Constructor del widget (permite recibir key si se necesita)
  const Formulario({super.key});

  @override
  // Crea el estado mutable asociado a este widget
  State<Formulario> createState() => _FormularioState();
}

// Estado interno del formulario
class _FormularioState extends State<Formulario> {
  // Key para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controllers para recuperar texto de los campos email y contraseña
  final _emailController = TextEditingController();
  final _contraController = TextEditingController();

  // Flag: ocultar/mostrar la contraseña en el campo
  bool _ocultar = true;

  // Flag 'recordarme' (checkbox)
  bool recordar = false;

  // Indica si se está realizando una petición (muestra loader y deshabilita botón)
  bool _isLoading = false; // estado de carga

  // Función asíncrona que realiza la petición de login al backend
  Future<void> iniciarSesion() async {
    // Obtener valores ingresados y limpiar espacios en blanco alrededor
    final email = _emailController.text.trim();
    final password = _contraController.text.trim();

    // Validación básica: campos vacíos
    if (email.isEmpty || password.isEmpty) {
      // Mostrar mensaje de error en la pantalla usando SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    // Indicamos que estamos cargando para bloquear UI mientras dura la petición
    setState(() {
      _isLoading = true;
    });

    try {
      // Endpoint del backend donde se solicita login
      final url = Uri.parse('http://localhost:8000/login');
      // Enviamos una petición POST con JSON (correo + password)
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'password': password}),
      );

      // Si el servidor responde OK (200) asumimos credenciales válidas
      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON y obtiene el id del transportista
        final data = jsonDecode(response.body);
        final transportistaIdRaw = data["id_r"];

        // Validación: si no viene id, informar error
        if (transportistaIdRaw == null) {
          // Mostrar snackbar indicando que no se obtuvo un id válido
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID de usuario inválido')),
          );
          return;
        }
        // Si el id no es int, lo convierte
        // Asegurarse de que el id sea un entero (podría venir como String)
        final transportistaId = transportistaIdRaw is int
            ? transportistaIdRaw
            : int.parse(transportistaIdRaw.toString());

        // Guardar la sesión - esto automáticamente triggereará la reconstrucción
        // Obtener el AuthProvider y guardar la sesión (persistencia + notificaciones)
        final authProvider = Provider.of<Authprovider>(context, listen: false);
        await authProvider.saveLogin(transportistaId, email);

        // Limpiar campos del formulario luego del login exitoso
        _emailController.clear();
        _contraController.clear();

        // Navegar a AuthWrapper (pantalla raíz) y eliminar historial para evitar back
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AuthWrapper()),
          (route) => false,
        );

        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(const SnackBar(content: Text('Bienvenido')));
      } else {
        // Código de respuesta distinto de 200 => credenciales incorrectas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } catch (e) {
      // Captura errores de conexión u otros fallos y muestra mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el servidor: $e')),
      );
    } finally {
      // Siempre quitar el estado de carga cuando termina la operación
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  // Construye la UI del formulario de inicio de sesión
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo principal de la pantalla (azul oscuro)
      backgroundColor: const Color.fromARGB(255, 29, 53, 87),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Espacio superior para separar del status bar
            const SizedBox(height: 50),
            Text(
              "Paquete Express",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Margen entre título y formulario
            const SizedBox(height: 16),
            Center(
              child: Container(
                // Caja blanca central que contiene el form
                width: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                // Widget Form para agrupar campos y validar
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Iniciar Sesión",
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        // Campo para ingresar el correo
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_rounded),
                          labelText: "Correo",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        // Validación simple: el campo no debe quedar vacío
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingrese su correo'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        // Campo para ingresar la contraseña, con opción de ocultar/mostrar
                        controller: _contraController,
                        obscureText: _ocultar,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.password_rounded),
                          labelText: "Contraseña",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // Suffix: icono que permite alternar visibilidad de la contraseña
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                // Cambia bandera para ocultar/mostrar texto
                                _ocultar = !_ocultar;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingrese su contraseña'
                            : null,
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: recordar,
                            onChanged: (value) {
                              setState(() {
                                recordar = value!;
                              });
                            },
                          ),
                          // Etiqueta al lado del checkbox
                          const Text("Recordarme"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null // Deshabilitar botón cuando está cargando
                            : () {
                                // Si el formulario es válido, ejecutar iniciarSesion
                                if (_formKey.currentState!.validate()) {
                                  iniciarSesion();
                                }
                              },
                        // Mostrar spinner en el botón mientras se realiza la petición
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text("Iniciar Sesión"),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormularioAdmin(),
                            ),
                          );
                        },
                        child: const Text("Inicio de sesion Administrador"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
Diccionario / Resumen (en español) — qué hace cada parte importante:

- Formulario: Widget principal que contiene el formulario de inicio de sesión.
- _formKey: Llave para validar el estado del formulario.
- _emailController, _contraController: Controladores para recuperar texto de los campos.
- _ocultar: Booleano que controla si la contraseña se muestra u oculta.
- recordar: Checkbox que representa la opción "Recordarme" (no persiste por defecto).
- _isLoading: Indica si se está realizando la petición de login; deshabilita botones.
- iniciarSesion(): Método asíncrono que valida campos, envía la petición POST al backend, procesa la respuesta, guarda la sesión usando AuthProvider y navega a la pantalla principal.
- AuthProvider.saveLogin(): Se usa para persistir el id y el correo en SharedPreferences y notificar a la app.
- Navigator.pushAndRemoveUntil(... AuthWrapper ...): Navega a la pantalla raíz y limpia el historial para evitar volver al login.

Notas:
- La URL del backend está apuntando a 'http://localhost:8000/login' — asegúrate de que el backend esté corriendo y accesible desde la app (emulador/dispositivo).
- El manejo de la opción 'recordar' actualmente sólo cambia la UI (no guarda en persistencia aquí). Se podría ampliar para que persista preferencias.
*/
