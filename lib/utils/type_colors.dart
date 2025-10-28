import 'package:flutter/material.dart';

/// Devuelve un color basado en el tipo de Pokémon.
Color getTypeColor(String type) {
  switch (type) {
    case 'grass':
      return Colors.green;
    case 'fire':
      return Colors.red;
    case 'water':
      return Colors.blue;
    case 'electric':
      return Colors.yellow;
    case 'psychic':
      return Colors.purple;
    case 'ice':
      return Colors.lightBlue;
    case 'dragon':
      return Colors.indigo;
    case 'dark':
      return Colors.brown;
    case 'fairy':
      return Colors.pink;
    case 'normal':
      return Colors.grey;
    case 'fighting':
      return Colors.orange;
    case 'flying':
      return Colors.lightBlue[300]!;
    case 'poison':
      return Colors.purple[800]!;
    case 'ground':
      return Colors.brown[400]!;
    case 'rock':
      return Colors.brown[600]!;
    case 'bug':
      return Colors.lightGreen[500]!;
    case 'ghost':
      return Colors.deepPurple;
    case 'steel':
      return Colors.blueGrey;
    default:
      return Colors.grey;
  }
}