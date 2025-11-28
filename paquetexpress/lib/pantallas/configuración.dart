import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../AuthProvider.dart';
import 'inicioSesion.dart';

class ConfiguracionScreen extends StatefulWidget {
  final int transportistaId;

  const ConfiguracionScreen({super.key, required this.transportistaId});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  Map<String, dynamic>? transportista;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransportista();
  }

  // ------------------ MÉTODO PARA OBTENER TRANSPORTISTA ------------------
  Future<void> _fetchTransportista() async {
    try {
      final url = Uri.parse(
        'http://localhost:8000/transportista/${widget.transportistaId}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transportista = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al obtener datos del transportista';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

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
        title: Text('Configuración'),
        backgroundColor: Colors.blue.shade900,
      ),
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          transportista!['rep_img'] != null &&
                              transportista!['rep_img'].toString().isNotEmpty
                          ? NetworkImage(transportista!['rep_img'])
                          : null,
                      child:
                          transportista!['rep_img'] == null ||
                              transportista!['rep_img'].toString().isEmpty
                          ? Icon(
                              Icons.person,
                              color: Colors.blue.shade900,
                              size: 40,
                            )
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre: ${transportista!['rep_nom'] ?? "-"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Apellido Paterno: ${transportista!['rep_app'] ?? "-"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Apellido Materno: ${transportista!['rep_apm'] ?? "-"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${transportista!['id_rep']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Licencia: ${transportista!['rep_licencia'] ?? "-"}',
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

            // Opciones de configuración
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
      Navigator.of(context).pop();

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
