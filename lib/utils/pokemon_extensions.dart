import 'package:flutter/material.dart';

extension StringExtensions on String {
  String get capitalize => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  String get cleanName {
    String raw = toLowerCase().trim();

    // 1. Casos Especiales de nombres largos
    if (raw.contains('tauros-paldea')) {
      if (raw.contains('combat')) return 'Paldea Tauros (Combat)';
      if (raw.contains('blaze')) return 'Paldea Tauros (Blaze)';
      if (raw.contains('aqua')) return 'Paldea Tauros (Aqua)';
      return 'Paldea Tauros';
    }
    if (raw == 'basculin-white-striped') return 'White-Striped Basculin';
    if (raw.contains('darmanitan-galar-standard')) return 'Galar Darmanitan';
    if (raw.contains('darmanitan-galar-zen')) return 'Galar Darmanitan (Zen)';

    // 2. Prefijos Regionales (Alola, Galar, Hisui, Paldea)
    String prefix = "";
    String name = raw;

    if (name.contains('-alola')) { prefix = "Alola "; name = name.replaceAll('-alola', ''); }
    else if (name.contains('-galar')) { prefix = "Galar "; name = name.replaceAll('-galar', ''); }
    else if (name.contains('-hisui')) { prefix = "Hisui "; name = name.replaceAll('-hisui', ''); }
    else if (name.contains('-paldea')) { prefix = "Paldea "; name = name.replaceAll('-paldea', ''); }

    String cleanBase = name.replaceAll('-', ' ').split(' ').map((w) => w.capitalize).join(' ');
    
    return "$prefix$cleanBase".trim();
  }

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
      case 'bug': return Colors.lightGreen[400]!;
      case 'ghost': return Colors.deepPurple;
      case 'steel': return Colors.blueGrey;
      case 'ground': return const Color(0xFFB08D57); 
      case 'rock': return const Color(0xFF6E5C4D);   
      case 'dark': return const Color(0xFF3C2D23);   
      default: return Colors.grey;
    }
  }
}