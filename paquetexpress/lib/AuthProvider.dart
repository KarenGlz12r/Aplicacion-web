// Import principal de Flutter (widgets y material design)
import 'package:flutter/material.dart';
import 'package:paquetexpress/pantallas/Admin.dart';
// Importa la pantalla de inicio que muestra la UI luego de autenticarse
import './pantallas/inicioSesion.dart';
// NOTE: La importación de DeliveryRoute se eliminó porque no se usa en este archivo.
// Importa el formulario/pantalla del menú o formulario de login
import './pantallas/menu.dart';
// Librería para persistir datos simples (par clave-valor) en el dispositivo
import 'package:shared_preferences/shared_preferences.dart';
import './pantallas/AdminInicio.dart';

// Clase que gestiona el estado de autenticación y notifica cambios a la UI
class Authprovider with ChangeNotifier {
  // Flag: true si hay una sesión activa, false en caso contrario
  bool _isloggedIn = false;

  // ID del transportista/Nullable cuando no hay sesión
  int? _transportista_id;

  // Email del usuario guardado en la sesión. Nullable si no existe.
  String? _usermail;

  // Marca si la verificación inicial (lectura de SharedPreferences) ya se hizo
  bool _isInitialized = false;
  bool _esAdmin = false;

  // Getter público para saber si hay sesión activa
  bool get isloggedIn => _isloggedIn;
  // Getter público que expone el id del transportista (nullable)
  int? get transportistaId => _transportista_id;
  // Getter público para obtener el email del usuario (nullable)
  String? get userEmail => _usermail;
  // Getter que indica si el provider ya verificó el estado de sesión
  bool get isInitialized => _isInitialized;

  static const List<String> admins = ['gabriel@example.com'];

  // Metodo para verificar si es admin
  bool get esAdmin => _esAdmin;

  // Constructor: arranca la inicialización automática al crear la instancia
  Authprovider() {
    // Inicia la comprobación asíncrona del estado de sesión
    _initialize();
  }

  // Método privado de inicialización que delega en checkLogin
  Future<void> _initialize() async {
    // Comprueba si ya existe una sesión guardada
    await checkLogin();
  }

  // Lee SharedPreferences para verificar si hay una sesión guardada
  Future<void> checkLogin() async {
    try {
      // Obtiene la instancia de SharedPreferences (acceso a almacenamiento persistente)
      final prefs = await SharedPreferences.getInstance();
      // Lee el id del transportista guardado (si existe)
      final saveTransId = prefs.getInt('transportista_id');
      // Lee el email de usuario guardado (si existe)
      final savedEmail = prefs.getString('user_email');
      final savedAdmin = prefs.getBool('esAdmin') ?? false;

      // Log para depuración con los valores leídos
      print(
        'Login: saveTransId=$saveTransId, savedEmail=$savedEmail, esAdmin=$savedAdmin',
      );
      // Si existe un id válido (>0), consideramos que existe una sesión
      if (saveTransId != null && saveTransId > 0) {
        // Marcar como logueado y asignar valores leídos de prefs
        _isloggedIn = true;
        _transportista_id = saveTransId;
        _usermail = savedEmail;
        _esAdmin = savedAdmin;
      } else {
        // No hay sesión: asegurar valores por defecto
        _isloggedIn = false;
        _transportista_id = null;
        _usermail = null;
        _esAdmin = false;
      }
    } catch (e) {
      // Manejo de errores: si hay fallo leyendo prefs, limpiamos el estado
      print(' Error en checkLogin: $e');
      _isloggedIn = false;
      _transportista_id = null;
      _usermail = null;
      _esAdmin = false;
    } finally {
      // Marcar como inicializado (aun en caso de error) y notificar a los listeners
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Guardar login del admin

  Future<void> saveAdminLogin(int admin, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('transportista_id', admin);
      await prefs.setString('user_email', email);
      await prefs.setBool('esAdmin', true);

      // Actualiza el estado interno: hay sesión activa
      _isloggedIn = true;
      // Guarda el id y email en memoria del provider
      _transportista_id = admin;
      _usermail = email;
      _esAdmin = true;

      // Log de confirmación
      print(' Sesión guardada: adminId=$admin, email=$email');
      // Notifica a la UI que el estado cambió
      notifyListeners();
    } catch (e) {
      // Si ocurre un error al guardar, imprimimos y re-lanzamos para manejo externo
      print(' Error en guardar login: $e');
      rethrow;
    }
  }

  // Guarda los datos de sesión (transportista_id y user_email) en SharedPreferences
  Future<void> saveLogin(int transportId, String email) async {
    try {
      // Obtiene la instancia de SharedPreferences para escribir datos
      final prefs = await SharedPreferences.getInstance();

      // Escribe el id del transportista en persistencia
      await prefs.setInt('transportista_id', transportId);
      // Escribe el email del usuario en persistencia
      await prefs.setString('user_email', email);
      await prefs.setBool('esAdmin', false);

      // Actualiza el estado interno: hay sesión activa
      _isloggedIn = true;
      // Guarda el id y email en memoria del provider
      _transportista_id = transportId;
      _usermail = email;
      _esAdmin = false;

      // Log de confirmación
      print(' Sesión guardada: transportId=$transportId, email=$email');
      // Notifica a la UI que el estado cambió
      notifyListeners();
    } catch (e) {
      // Si ocurre un error al guardar, imprimimos y re-lanzamos para manejo externo
      print(' Error en guardar login: $e');
      rethrow;
    }
  }

  // Limpia la sesión tanto en memoria como en persistencia
  Future<void> logout() async {
    try {
      // Mensaje indicativo de inicio de logout
      print(' Ejecutando logout');

      // Obtiene SharedPreferences para eliminar las claves de sesión
      final prefs = await SharedPreferences.getInstance();

      // Elimina el id del transportista de la persistencia
      await prefs.remove('transportista_id');
      // Elimina el email del usuario de la persistencia
      await prefs.remove('user_email');
      await prefs.remove('esaAdmin');

      // Actualiza el estado interno: ya no hay sesión
      _isloggedIn = false;
      _transportista_id = null;
      _usermail = null;
      _esAdmin = false;

      // Confirma la finalización del logout
      print(' Logout completado');
      // Notifica a la UI sobre el cambio de estado
      notifyListeners();
    } catch (e) {
      // En caso de error, log y rethrow para permitir manejo por el llamador
      print(' Error en logout: $e');
      rethrow;
    }
  }

  int? getTransportista() {
    return _transportista_id;
  }

  // Construye y devuelve el widget inicial correcto según el estado de autenticación
  Widget getAuthWrapper() {
    // Si aún no se ha completado la inicialización: mostrar loader
    if (!_isInitialized) {
      return Scaffold(
        // Fondo oscuro mientras carga el estado
        backgroundColor: const Color.fromARGB(255, 4, 6, 48),
        body: Center(
          // Indicador circular en blanco para indicar carga
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // Si hay sesión válida y se conoce el id del transportista, mostrar inicio
    if (_isloggedIn && _transportista_id != null) {
      if (esAdmin) {
        return AdminPanel();
      }
      // Si está logueado, retorna la pantalla de inicio, pasando el id
      else {
        return Inicio(transportistaId: _transportista_id!);
      }
    } else {
      // En caso contrario, mostrar el formulario de inicio de sesión
      return Formulario();
    }
  }
}

/*
Diccionario de términos (en español) - clave: explicación clara

- Authprovider: Clase que gestiona el estado de autenticación y notifica cambios
- ChangeNotifier: Mecanismo de Flutter para que la UI escuche cambios de estado
- SharedPreferences: API para persistencia simple de pares clave-valor en el dispositivo
- _isloggedIn: bool -> Flag que indica si existe una sesión activa (true/false)
- _transportista_id: int? -> Identificador del transportista almacenado en sesión; puede ser null
- _usermail: String? -> Correo electrónico del usuario guardado en sesión; nullable
- _isInitialized: bool -> Indica si ya se comprobó el estado persistente al iniciar
- isloggedIn: getter -> Expone _isloggedIn al resto de la app
- transportistaId: getter -> Expone _transportista_id al resto de la app
- userEmail: getter -> Expone _usermail al resto de la app
- isInitialized: getter -> Expone si el provider ya hizo la comprobación inicial
- Authprovider() -> Constructor que dispara la inicialización asíncrona
- _initialize() -> Método privado inicial que llama a checkLogin()
- checkLogin() -> Lee SharedPreferences para determinar si existe sesión guardada
- saveLogin(id, email) -> Guarda id y email en SharedPreferences y actualiza el estado
- logout() -> Elimina las claves de sesión en SharedPreferences y limpia el estado
- getAuthWrapper() -> Devuelve el widget inicial según el estado: loader / Inicio / Formulario

Notas:
- Este archivo está pensado para usarse junto a un mecanismo de proveedor (Provider) en Flutter.
- Si aparece un lint de "unused import" para `DeliveryRoute.dart`, se puede eliminar si no se usa.
*/

/*
Diccionario de términos (al final del archivo) — clave: explicación breve

- _isloggedIn: bool -> Indica si hay una sesión activa.
- _transportista_id: int? -> ID del usuario/transportista almacenado, puede ser null.
- _usermail: String? -> Email del usuario guardado en SharedPreferences.
- _isInitialized: bool -> Marca que se completó la verificación de sesión al inicializar.
- checkLogin(): Future<void> -> Lee SharedPreferences, actualiza el estado interno y notifica listeners.
- saveLogin(transportId, email): Future<void> -> Guarda id y email en SharedPreferences y actualiza el estado.
- logout(): Future<void> -> Elimina los datos de sesión de SharedPreferences y actualiza el estado.
- getAuthWrapper(): Widget -> Devuelve el widget correspondiente según el estado (carga, logged in, o login form).
- SharedPreferences: -> Librería para persistir pares clave-valor simples en el dispositivo.
- ChangeNotifier: -> Clase de Flutter para notificar a widgets que han escuchado cambios (Provider, etc.).

*/
