// Necesario para convertir respuestas JSON del backend a objetos Dart
import 'dart:convert';
// Import principal de Flutter para widgets y elementos de UI
import 'package:flutter/material.dart';
// Provider: permite leer y usar providers (estado global) dentro del widget tree
import 'package:provider/provider.dart';
// Cliente HTTP para hacer requests al servidor (GET en este archivo)
import 'package:http/http.dart' as http;
// Provider local que maneja la autenticación y persistencia de sesión
import '../AuthProvider.dart';

// Nota: `inicioSesion.dart` estaba importado pero no se usa — lo hemos eliminado

// Pantalla/Widget principal de configuración para el transportista
class ConfiguracionScreen extends StatefulWidget {
  // ID del transportista cuyo perfil/configuración se mostrará
  final int transportistaId;

  // Constructor requiere el id del transportista
  const ConfiguracionScreen({super.key, required this.transportistaId});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

// Estado privado de la pantalla Configuración
class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  // Mapa que contendrá los datos del transportista traídos del backend
  Map<String, dynamic>? transportista;

  // Flag para indicar que la pantalla está cargando datos
  bool isLoading = true;

  // Mensaje de error si la petición falla
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransportista();
  }

  // ------------------ MÉTODO PARA OBTENER DATOS DEL TRANSPORTISTA ------------------
  // Hace una petición GET al backend y actualiza el estado con la respuesta
  Future<void> _fetchTransportista() async {
    try {
      // Construye la URL del endpoint usando el transportistaId del widget
      final url = Uri.parse(
        'http://localhost:8000/transportista/${widget.transportistaId}',
      );
      final response = await http.get(url);

      // Si la respuesta es exitosa (200) decodificamos JSON y asignamos
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transportista = data;
          isLoading = false; // ya no está cargando
        });
      } else {
        // En caso de respuesta no exitosa, mostramos un mensaje de error
        setState(() {
          errorMessage = 'Error al obtener datos del transportista';
          isLoading = false;
        });
      }
    } catch (e) {
      // Captura excepciones de red u otras y actualiza estado con mensaje
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el AuthProvider para poder ejecutar logout más abajo
    final authProvider = Provider.of<Authprovider>(context, listen: false);

    // Si aún estamos cargando datos, mostramos un indicador circular
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si hubo un error al cargar la información, mostramos el mensaje
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $errorMessage')));
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: Colors.blue.shade900,
      ),
      // Contenido principal con padding general
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjeta de información del transportista
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del transportista (o '-' si no existe)
                          Text(
                            'Nombre: ${transportista!['r_nomC'] ?? "-"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          // Espacio pequeño entre textos
                          SizedBox(height: 4),
                          // Mostramos el ID del transportista
                          Text(
                            'ID: ${transportista!['id_r']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Bloque de opciones de configuración (lista desplazable)
            Expanded(
              child: ListView(
                children: [
                  // Opción: Notificaciones
                  _buildOptionCard(
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    subtitle: 'Configurar alertas y notificaciones',
                    onTap: () {},
                  ),
                  // Opción: Privacidad y seguridad
                  _buildOptionCard(
                    icon: Icons.security,
                    title: 'Privacidad',
                    subtitle: 'Configuración de privacidad y seguridad',
                    onTap: () {},
                  ),
                  // Opción: Ayuda y soporte
                  _buildOptionCard(
                    icon: Icons.help,
                    title: 'Ayuda y Soporte',
                    subtitle: 'Centro de ayuda y contacto',
                    onTap: () {},
                  ),
                  SizedBox(height: 24),
                  // Tarjeta especial para Cerrar Sesión (visual destacada)
                  Card(
                    elevation: 4,
                    color: Colors.red.shade50,
                    child: ListTile(
                      // Icono rojo que indica acción de logout
                      leading: Icon(Icons.logout, color: Colors.red),
                      // Título principal del item: Cerrar Sesión
                      title: Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Descripción secundaria explicando la acción
                      subtitle: Text(
                        'Salir de tu cuenta actual',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      // Icono que indica que se puede pulsar para avanzar
                      trailing: Icon(Icons.chevron_right, color: Colors.red),
                      // Pulsar abre un diálogo de confirmación de logout
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

  // Helper que construye una tarjeta de opción reutilizable
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        // Icono principal de la opción con color corporativo
        leading: Icon(icon, color: Colors.blue.shade800),
        title: Text(title),
        subtitle: Text(subtitle),
        // Indica que la fila es tappable y navega a más opciones
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Muestra un diálogo modal pidiendo confirmación antes de cerrar sesión
  void _showLogoutDialog(BuildContext context, Authprovider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Definimos el contenido del AlertDialog con botones de acción
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            // Botón cancelar: cierra el diálogo sin acción
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Botón cerrar sesión: cierra el diálogo y ejecuta logout
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
    // Mostrar diálogo de carga mientras se procesa el logout
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Ejecuta el logout en el AuthProvider (limpia SharedPreferences y estado)
      await authProvider.logout();

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Tras logout, el listener/Consumer en main.dart detectará el cambio de estado
      // y navegará a la pantalla de login (no lo hacemos explícitamente aquí)
    } catch (e) {
      // En caso de error, cerramos el diálogo y mostramos una notificación
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }
}

/*
Diccionario / Resumen (en español):

- ConfiguracionScreen: Pantalla que muestra datos del transportista y opciones de configuración.
- transportistaId: ID usado para solicitar datos del transportista al backend.
- _fetchTransportista(): Hace GET al endpoint /transportista/{id} y guarda los datos recibidos.
- isLoading: Bandera que indica si aún se está cargando la información.
- errorMessage: Guarda texto de error si ocurre un fallo en la petición.
- _buildOptionCard(): Helper que crea tarjetas de opción reutilizables.
- _showLogoutDialog(): Muestra diálogo de confirmación antes de cerrar sesión.
- _performLogout(): Ejecuta el logout mediante AuthProvider, muestra un diálogo de progreso y maneja errores.

Notas:
- La URL del backend está configurada a 'http://localhost:8000' — verificar accesibilidad desde el emulador/dispositivo.
- Se eliminó la importación de `inicioSesion.dart` porque no se usa en este archivo. Si lo necesitas, puedes volver a agregarlo.
*/
