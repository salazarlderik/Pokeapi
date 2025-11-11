import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'region_screen.dart';

/// Punto de entrada principal de la aplicación.
/// Inicializa Flutter y el sistema de localización antes de correr la app.
Future<void> main() async {
  // Asegura que los bindings nativos de Flutter estén listos.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa el sistema de traducción (EasyLocalization).
  await EasyLocalization.ensureInitialized();

  runApp(
    // Envuelve la aplicación raíz con el widget de EasyLocalization.
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('es')], // Idiomas soportados
      path: 'assets/translations', // Ruta a los archivos JSON
      fallbackLocale: Locale('en'), // Idioma de respaldo si falla
      child: MyApp(),
    ),
  );
}

/// Widget raíz de la aplicación.
/// Construye el [MaterialApp] y define el tema global y la localización.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PokeApi App', // Título interno usado por el OS

      // --- Configuración de Localización ---
      // Conecta el MaterialApp con los delegados de EasyLocalization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale, // Define el idioma actual de la app

      // --- Configuración del Tema Global ---
      themeMode: ThemeMode.light, // Forza el modo claro
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.redAccent,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),
      ),

      /// Define la pantalla inicial que se mostrará.
      home: RegionScreen(),
    );
  }
}