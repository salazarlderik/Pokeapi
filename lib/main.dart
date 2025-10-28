import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importa Provider
import 'pokemon_provider.dart'; // 2. Importa tu Provider
import 'pokemon_screen.dart';

void main() {
  // 3. Envuelve la app con el ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => PokemonProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon App',
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
      home: PokemonScreen(),
    );
  }
}