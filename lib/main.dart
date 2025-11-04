import 'package:flutter/material.dart';
import 'region_screen.dart'; // Importa la nueva pantalla de regiones

/// Punto de entrada principal de la aplicación.
void main() {
  // El Provider ya no se crea aquí, se creará por cada región.
  runApp(MyApp());
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeApi App',
      themeMode: ThemeMode.light,
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
      // La nueva pantalla de inicio es la lista de regiones.
      home: RegionScreen(),
    );
  }
}