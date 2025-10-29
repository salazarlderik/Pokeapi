import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_screen.dart';


void main() {
  runApp(
    // Provee el estado de PokemonProvider al árbol de widgets.
    ChangeNotifierProvider(
      create: (context) => PokemonProvider(),
      child: MyApp(),
    ),
  );
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeApi App', 
      themeMode: ThemeMode.light, // Forza el tema claro siempre
      theme: ThemeData( // Define la apariencia general de la app
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
      home: PokemonScreen(),
    );
  }
}