import 'package:flutter/material.dart';
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
        builder: (context, authProvider, child) {
          return authProvider.getAuthWrapper();
        },
      ),
    );
  }
}
