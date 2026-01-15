import 'package:easy_localization/easy_localization.dart';
import 'pokemon_constants.dart';
import 'pokemon_extensions.dart';

class EvolutionHelper {
  static String getEvoNodeName(String base, String suffix) {
    if (base == 'dudunsparce') return 'dudunsparce-two-segment';
    if (PokeConstants.galarianEvolutions.contains(base) || 
        PokeConstants.hisuianEvolutions.contains(base) || 
        PokeConstants.paldeanEvolutions.contains(base)) return base;
    
    if (suffix == '-alola' && PokeConstants.alolanForms.contains(base)) return '$base$suffix';
    if (suffix == '-galar' && PokeConstants.galarianForms.contains(base)) return '$base$suffix';
    if (suffix == '-hisui' && PokeConstants.hisuianForms.contains(base)) return '$base$suffix';
    return base;
  }

  static List filterEvolutions(List evos, String base, String suffix) {
    return evos.where((e) {
      String name = e['species']['name'];
      if (suffix == '-galar') {
        return PokeConstants.galarianEvolutions.contains(name) || 
               PokeConstants.galarianForms.contains(name);
      }
      if (suffix == '-hisui') return PokeConstants.hisuiLine.contains(name);
      if (suffix == '-paldea') return PokeConstants.paldeaLine.contains(name);
      return !PokeConstants.galarianEvolutions.contains(name);
    }).toList();
  }

  static String formatEvoDetails(List details, String to) {
    if (details.isEmpty) return "";
    final d = details.first;
    final String target = to.toLowerCase();

    // --- CORRECCIONES MANUALES DE MÉTODOS COMPLEJOS ---
    
    // Annihilape (Primeape)
    if (target == 'annihilape') return "Use Rage Fist 20 times & Lvl Up";
    
    // Sirfetch'd (Farfetch'd Galar)
    if (target == 'sirfetchd') return "3 critical hits in a single battle";
    
    // Leafeon y Glaceon (Método moderno por piedras)
    if (target == 'leafeon') return "Leaf Stone";
    if (target == 'glaceon') return "Ice Stone";
    
    // Electrode de Hisui (Evoluciona de Voltorb Hisui)
    if (target == 'electrode-hisui') return "Leaf Stone";

    // --- LÓGICA POR DISPARADORES ---
    
    // Intercambio (Trade)
    if (d['trigger']['name'] == 'trade') {
      String tradeText = "Trade";
      if (d['held_item'] != null) {
        return "$tradeText + ${d['held_item']['name'].toString().cleanName.capitalize}";
      }
      return tradeText;
    }

    // Uso de Objetos (Piedras)
    if (d['item'] != null) {
      String itemName = d['item']['name'].toString().toLowerCase();
      
      // Excepción Alola (Vulpix y Sandshrew)
      if (target.contains('-alola') && itemName.contains('ice-stone')) {
        return "Ice Stone";
      }
      return itemName.cleanName.capitalize;
    }

    // Subida de Nivel y Condiciones
    if (d['trigger']['name'] == 'level-up') {
      
      // Eevee: Espeon, Umbreon y Sylveon
      if (target == 'espeon') return "Friendship (Day) & Lvl Up";
      if (target == 'umbreon') return "Friendship (Night) & Lvl Up";
      if (target == 'sylveon') return "Friendship + Fairy Move & Lvl Up";

      // Alolan Meowth / Persian (Amistad)
      if (target == 'persian-alola' || (target == 'persian' && d['min_happiness'] != null)) {
        return "Friendship & Lvl Up";
      }

      // Línea de Tyrogue
      if (target == 'hitmonlee') return "Lvl 20 (Atk > Def)";
      if (target == 'hitmonchan') return "Lvl 20 (Def > Atk)";
      if (target == 'hitmontop') return "Lvl 20 (Atk = Def)";

      // Happiny -> Chansey
      if (target == 'chansey' && d['held_item'] != null) return "Lvl Up (Day) + Oval Stone";

      // Nivel y tiempo (Marowak Alola Lvl 28 Night)
      if (d['min_level'] != null) {
        String lvl = "Lvl ${d['min_level']}";
        if (d['time_of_day'] == 'night') return "$lvl (Night)";
        if (d['time_of_day'] == 'day') return "$lvl (Day)";
        return lvl;
      }

      if (d['min_happiness'] != null) return "Friendship & Lvl Up";
      if (d['known_move'] != null) return "Lvl Up knowing ${d['known_move']['name'].toString().cleanName.capitalize}";
      if (d['location'] != null) return "Lvl Up in Magnetic Field";
    }

    return d['trigger']['name'].toString().cleanName.capitalize;
  }
}