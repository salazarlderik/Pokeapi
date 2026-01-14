import 'package:flutter/material.dart';

extension StringExtensions on String {
  String get capitalize => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  String get cleanName => replaceAll('-', ' ').split(' ').map((w) => w.capitalize).join(' ');

  Color get toTypeColor {
    switch (toLowerCase()) {
      case 'grass': return Colors.green;
      case 'fire': return Colors.red;
      case 'water': return Colors.blue;
      case 'electric': return Colors.yellow;
      case 'psychic': return const Color(0xFFF95587); 
      case 'ice': return Colors.lightBlue;
      case 'dragon': return Colors.indigo;
      case 'fairy': return Colors.pink;
      case 'normal': return Colors.grey;
      case 'fighting': return Colors.orange;
      case 'flying': return Colors.lightBlue[300]!;
      case 'poison': return const Color(0xFF6A1B9A); 
      case 'bug': return Colors.lightGreen[400]!; // Verde claro base para Bicho
      case 'ghost': return Colors.deepPurple;
      case 'steel': return Colors.blueGrey;

      // COLORES PERSONALIZADOS
      case 'ground': return const Color(0xFFB08D57); 
      case 'rock': return const Color(0xFF6E5C4D);   
      case 'dark': return const Color(0xFF3C2D23);   

      default: return Colors.grey;
    }
  }
}