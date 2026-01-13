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
    if (to.startsWith('lycanroc')) {
      return d['time_of_day'] == 'night' 
          ? 'evolutions.override_lycanroc_night'.tr() 
          : 'evolutions.override_lycanroc_day'.tr();
    }
    if (d['min_level'] != null) return 'evolutions.lvl'.tr(namedArgs: {'level': d['min_level'].toString()});
    if (d['item'] != null) return 'evolutions.use_item'.tr(namedArgs: {'item': d['item']['name'].toString().cleanName});
    return d['trigger']['name'].toString().cleanName;
  }
}