import 'package:flutter/material.dart';

extension StringExtensions on String {
  // Convierte 'bulbasaur' en 'Bulbasaur'
  String get capitalize => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  // Limpia los nombres de la API (ej. 'special-attack' -> 'Special Attack')
  String get cleanName => replaceAll('-', ' ').split(' ').map((w) => w.capitalize).join(' ');

  // Obtiene el color directamente del String del tipo: 'fire'.toTypeColor
  Color get toTypeColor {
    switch (toLowerCase()) {
      case 'grass': return Colors.green;
      case 'fire': return Colors.red;
      case 'water': return Colors.blue;
      case 'electric': return Colors.yellow;
      case 'psychic': return Colors.purple;
      case 'ice': return Colors.lightBlue;
      case 'dragon': return Colors.indigo;
      case 'dark': return Colors.brown;
      case 'fairy': return Colors.pink;
      case 'normal': return Colors.grey;
      case 'fighting': return Colors.orange;
      case 'flying': return Colors.lightBlue[300]!;
      case 'poison': return Colors.purple[800]!;
      case 'ground': return Colors.brown[400]!;
      case 'rock': return Colors.brown[600]!;
      case 'bug': return Colors.lightGreen[500]!;
      case 'ghost': return Colors.deepPurple;
      case 'steel': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }
}