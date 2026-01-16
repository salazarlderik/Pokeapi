import 'package:easy_localization/easy_localization.dart';
import 'pokemon_constants.dart';
import 'pokemon_extensions.dart';

class EvolutionHelper {
  static String getEvoNodeName(String base, String suffix) {
    if (base == 'dudunsparce') return 'dudunsparce-two-segment';
    if (base == 'maushold') return 'maushold-family-of-three';
    if (base == 'basculin' && suffix == '-hisui') return 'basculin-white-striped';
    if (base == 'yamask' && suffix == '-galar') return 'yamask-galar';
    if (base == 'darmanitan' && suffix == '-galar') return 'darmanitan-galar-standard';
    if (base == 'tauros' && suffix == '-paldea') return 'tauros-paldea-combat-breed';

    if (suffix.isNotEmpty && !base.contains(suffix)) {
      if ((suffix == '-alola' && PokeConstants.alolanForms.contains(base)) ||
          (suffix == '-galar' && PokeConstants.galarianForms.contains(base)) ||
          (suffix == '-hisui' && PokeConstants.hisuianForms.contains(base)) ||
          (suffix == '-paldea' && PokeConstants.paldeanForms.contains(base))) {
        return '$base$suffix';
      }
    }
    return base;
  }

  static List filterEvolutions(List evos, String base, String suffix, String currentName) {
    if (base == 'manaphy' || base == 'phione') return [];
    final cName = currentName.toLowerCase();

    return evos.where((e) {
      String name = e['species']['name'];

      // Filtro reactivo para Rockruff -> Lycanroc
      if (base == 'rockruff') {
        if (cName.contains('midnight')) return name == 'lycanroc-midnight';
        if (cName.contains('dusk')) return name == 'lycanroc-dusk';
        return name == 'lycanroc-midday' || name == 'lycanroc';
      }

      // Filtro reactivo para Basculin -> Basculegion
      if (base == 'basculin') {
        return cName.contains('white-striped') && name == 'basculegion';
      }

      if (base == 'wooper') return suffix == '-paldea' ? name == 'clodsire' : name == 'quagsire';
      if (base == 'sneasel') return suffix == '-hisui' ? name == 'sneasler' : name == 'weavile';
      if (base == 'qwilfish') return suffix == '-hisui' && name == 'overqwil';

      if (['ursaluna', 'wyrdeer', 'kleavor', 'annihilape', 'farigiraf', 'dudunsparce', 'kingambit', 'basculegion', 'runerigus', 'overqwil', 'archaludon', 'dipplin', 'hydrapple', 'pawmot', 'maushold', 'brambleghast', 'rabsca', 'palafin', 'gholdengo', 'sinistcha'].contains(name)) return true;

      if (suffix == '-galar') return PokeConstants.galarianEvolutions.contains(name) || PokeConstants.galarianForms.contains(name);
      if (suffix == '-hisui') return PokeConstants.hisuiLine.contains(name);
      if (suffix == '-paldea') return PokeConstants.paldeaLine.contains(name);
      
      return !PokeConstants.galarianEvolutions.contains(name) && !PokeConstants.hisuianEvolutions.contains(name) && name != 'clodsire' && name != 'manaphy' && name != 'phione' && name != 'runerigus';
    }).toList();
  }

  static String formatEvoDetails(List details, String to) {
    final String target = to.toLowerCase();

    // PRIORIDAD 0: OVERRIDES MANUALES (Manteniendo toda tu lista intacta)
    if (target.contains('persian-alola')) return "Friendship & Lvl Up";
    if (target.contains('raticate-alola')) return "Lvl 20 (Night)";
    if (target.contains('raichu-alola')) return "Thunder Stone";
    if (target.contains('sandslash-alola')) return "Ice Stone";
    if (target.contains('ninetales-alola')) return "Ice Stone";
    if (target.contains('marowak-alola')) return "Lvl 28 (Night)";
    if (target.contains('vikavolt')) return "Magnetic Field or Thunder Stone";
    if (target.contains('crabominable')) return "Mount Lanakila or Ice Stone";
    if (target.contains('salazzle')) return "Lvl 33 (Female only)";
    if (target.contains('solgaleo')) return "Lvl 53 (Sun/Ultra Sun/Sword)";
    if (target.contains('lunala')) return "Lvl 53 (Moon/Ultra Moon/Shield)";
    if (target.contains('lycanroc-midday')) return "Lvl 25 (Day)";
    if (target.contains('lycanroc-midnight')) return "Lvl 25 (Night)";
    if (target.contains('lycanroc-dusk')) return "Lvl 25 (Dusk) + Own Tempo";
    if (target == 'leafeon') return "Leaf Stone";
    if (target == 'glaceon') return "Ice Stone";
    if (target.contains('slowbro-galar')) return "Galarica Cuff";
    if (target.contains('slowking-galar')) return "Galarica Wreath";
    if (target.contains('sirfetchd')) return "3 critical hits in a battle";
    if (target.contains('darmanitan-galar')) return "Ice Stone";
    if (target.contains('obstagoon')) return "Lvl 35 (Night)";
    if (target.contains('perrserker')) return "Lvl 28";
    if (target.contains('dipplin')) return "Syrupy Apple";
    if (target.contains('hydrapple')) return "Lvl Up knowing Dragon Cheer";
    if (target.contains('archaludon')) return "Metal Alloy";
    if (target.contains('polteageist')) return "Cracked or Chipped Pot";
    if (target.contains('sinistcha')) return "Unremarkable or Masterpiece Teacup";
    if (target.contains('urshifu')) return "Scroll of Darkness or Waters";
    if (target.contains('alcremie')) return "Hold Sweet item & Spin device";
    if (target.contains('pawmot')) return "Walk 1000 steps (Let's Go) & Lvl Up";
    if (target.contains('maushold')) return "Lvl 25 (May evolve without animation)";
    if (target.contains('brambleghast')) return "Walk 1000 steps (Let's Go) & Lvl Up";
    if (target.contains('rabsca')) return "Walk 1000 steps (Let's Go) & Lvl Up";
    if (target.contains('palafin')) return "Lvl 38+ in Union Circle";
    if (target.contains('gholdengo')) return "Lvl Up with 999 Coins";
    if (target.contains('annihilape')) return "Use Rage Fist 20 times & Lvl Up";
    if (target.contains('kingambit')) return "Defeat 3 Leader Bisharp & Lvl Up";
    if (target.contains('basculegion')) return "White-Striped: 300 Recoil Damage & Lvl Up";
    if (target.contains('ursaluna')) return "Peat Block during a Full Moon";
    if (target.contains('wyrdeer')) return "Use Psyshield Bash (Agile) 20 times";
    if (target.contains('kleavor')) return "Black Augurite";
    if (target.contains('overqwil')) return "Use Barb Barrage (Strong) 20 times";
    if (target.contains('sneasler')) return "Lvl Up holding Razor Claw (Day)";
    if (target.contains('electrode-hisui')) return "Leaf Stone";
    if (target.contains('runerigus')) return "Take 49+ damage & pass under Arch";
    if (target.contains('escavalier')) return "Trade for Shelmet";
    if (target.contains('accelgor')) return "Trade for Karrablast";
    if (target == 'gliscor') return "Lvl Up holding Razor Fang (Night)";
    if (target == 'weavile') return "Lvl Up holding Razor Claw (Night)";
    if (target == 'malamar') return "Lvl 30 + Hold device upside down";
    if (target == 'tyrantrum') return "Lvl 39 (Day)";
    if (target == 'aurorus') return "Lvl 39 (Night)";
    if (target.contains('goodra')) return "Lvl 50 during Rain or Fog";
    if (target == 'shedinja') return "Lvl 20 + Empty Slot & Poké Ball";
    if (target == 'milotic') return "Prism Scale (Trade) or High Beauty";
    if (target == 'gallade') return "Dawn Stone (Male only)";
    if (target == 'froslass') return "Dawn Stone (Female only)";
    if (target == 'mantine') return "Lvl Up with Remoraid in Party";
    if (target == 'vespiquen') return "Lvl 21 (Female only)";
    if (target == 'mothim') return "Lvl 20 (Male only)";
    if (target == 'wormadam') return "Lvl 20 (Female only)";

    if (details.isEmpty) return "";
    Map<String, dynamic> selectedDetail = details.first; 
    for (var d in details) {
      final held = d['held_item']?['name']?.toString() ?? "";
      final time = d['time_of_day'] ?? "";
      final gender = d['gender'];
      if (target.contains('gallade') && gender == 2) { selectedDetail = d; break; }
      if (target.contains('froslass') && gender == 1) { selectedDetail = d; break; }
      if (target.contains('chansey') && (d['item']?['name'] == 'oval-stone' || held.contains('oval'))) { selectedDetail = d; break; }
    }

    final trigger = selectedDetail['trigger']['name'];
    final timeOfDay = selectedDetail['time_of_day'] ?? "";

    if (trigger == 'trade') {
      if (selectedDetail['held_item'] != null) return "Trade + ${selectedDetail['held_item']['name'].toString().cleanName.capitalize}";
      return "Trade";
    }
    if (selectedDetail['item'] != null) return selectedDetail['item']['name'].toString().cleanName.capitalize;
    if (trigger == 'level-up') {
      if ((target.contains('magnezone') || target.contains('probopass') || target.contains('vikavolt')) && (selectedDetail['location'] != null || selectedDetail['item'] != null)) return "Magnetic Field or Thunder Stone";
      if (target.contains('chansey')) return "Lvl Up holding Oval Stone (Day)";
      if (target.contains('espeon')) return "Friendship (Day) & Lvl Up";
      if (target.contains('umbreon')) return "Friendship (Night) & Lvl Up";
      if (target.contains('sylveon')) return "Friendship + Fairy Move & Lvl Up";
      if (selectedDetail['min_level'] != null) {
        String lvl = "Lvl ${selectedDetail['min_level']}";
        if (target.contains('hitmonlee')) return "$lvl (Atk > Def)";
        if (target.contains('hitmonchan')) return "$lvl (Def > Atk)";
        if (target.contains('hitmontop')) return "$lvl (Atk = Def)";
        if (timeOfDay == 'night') return "$lvl (Night)";
        if (timeOfDay == 'day') return "$lvl (Day)";
        return lvl;
      }
      if (selectedDetail['min_happiness'] != null) return "Friendship & Lvl Up";
      if (selectedDetail['known_move'] != null) return "Lvl Up knowing ${selectedDetail['known_move']['name'].toString().cleanName.capitalize}";
    }
    return trigger.toString().cleanName.capitalize;
  }
}