import 'package:flutter/material.dart';
import 'pokemon_screen.dart';

void main() {
  runApp(MyApp());
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
      home: PokemonScreen(), // Define la pantalla inicial de la aplicación
    );
  }
}