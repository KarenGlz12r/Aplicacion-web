import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../AuthProvider.dart';
import 'Admin.dart';
// import 'registro.dart';

class FormularioAdmin extends StatefulWidget {
  const FormularioAdmin({super.key});

  @override
  State<FormularioAdmin> createState() => _FormularioState();
}

class _FormularioState extends State<FormularioAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _contraController = TextEditingController();
  bool _ocultar = true;
  bool recordar = false;
  bool _isLoading = false; // Agregar estado de carga

  Future<void> iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _contraController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:8000/login/admin');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final adminId = data["id"];

        if (adminId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID de usuario inválido')),
          );
          return;
        }

        // Guardar la sesión - esto automáticamente triggereará la reconstrucción
        final authProvider = Provider.of<Authprovider>(context, listen: false);
        await authProvider.saveAdminLogin(adminId, email);

        _emailController.clear();
        _contraController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenido Administrador')),
        );

        // Navegar
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminPanel()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el servidor: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 53, 87),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              "Paquete Express",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
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
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_rounded),
                          labelText: "Correo",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingrese su correo'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contraController,
                        obscureText: _ocultar,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.password_rounded),
                          labelText: "Contraseña",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
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
                          const Text("Recordarme"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null // Deshabilitar botón cuando está cargando
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  iniciarSesion();
                                }
                              },
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
