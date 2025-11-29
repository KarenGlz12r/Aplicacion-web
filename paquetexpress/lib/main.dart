import 'package:flutter/material.dart';
import 'package:paquetexpress/pantallas/Admin.dart';
import 'package:paquetexpress/pantallas/inicioSesion.dart';
import 'package:paquetexpress/pantallas/menu.dart';
import 'AuthProvider.dart';
import 'DeliveryRoute.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => Authprovider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PaquetExpress',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<Authprovider>(
        builder: (context, authProvider, child) => AuthWrapper(),
      ),
    );
  }
}

// Maneja la logica de sesiones
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<Authprovider>(context);

    // Si aún no se inicializó, mostrar loading
    if (!authProvider.isInitialized) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 4, 6, 48),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // Si está logueado como admin, ir a AdminPanel
    if (authProvider.isloggedIn && authProvider.esAdmin) {
      return AdminPanel();
    }

    // Si está logueado como repartidor, ir a Inicio
    if (authProvider.isloggedIn && authProvider.transportistaId != null) {
      return Inicio(transportistaId: authProvider.transportistaId!);
    }

    // Si no está logueado, mostrar Formulario principal
    return Formulario();
  }
}
