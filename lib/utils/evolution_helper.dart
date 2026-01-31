import 'package:easy_localization/easy_localization.dart';
import 'pokemon_extensions.dart';
import 'pokemon_constants.dart';

class EvolutionHelper {
  // --- MAPA DE SEGURIDAD (OVERRIDES MANUALES) ---
  static const Map<String, String> _manualOverrides = {
    // --- KANTO / JOHTO ---
    'pichu': 'Friendship',
    'cleffa': 'Friendship',
    'igglybuff': 'Friendship',
    'golbat': 'Lvl 22', // Zubat -> Golbat (Nivel)
    'crobat': 'Friendship', // Golbat -> Crobat (Amistad)
    'chansey': 'Lvl Up holding Oval Stone (Day)', // Happiny -> Chansey
    'blissey': 'Friendship', // Chansey -> Blissey
    'munchlax': 'Friendship',
    'lucario': 'Friendship (Day)', // Riolu -> Lucario
    'riolu': 'Hatch Egg', 

    // Intercambios especiales
    'slowking': 'Trade + King\'s Rock',
    'politoed': 'Trade + King\'s Rock',
    'steelix': 'Trade + Metal Coat',
    'scizor': 'Trade + Metal Coat',
    'kingdra': 'Trade + Dragon Scale',
    'porygon2': 'Trade + Upgrade',
    'porygon-z': 'Trade + Dubious Disc',
    'huntail': 'Trade + Deep Sea Tooth',
    'gorebyss': 'Trade + Deep Sea Scale',
    'milotic': 'Trade + Prism Scale (or High Beauty)',
    
    // Casos especiales Kanto/Johto
    'mantine': 'Lvl Up with Remoraid in party',
    'shedinja': 'Lvl 20 + Empty Slot & Poké Ball',
    'hitmontop': 'Lvl 20 (Atk = Def)',
    'hitmonlee': 'Lvl 20 (Atk > Def)',
    'hitmonchan': 'Lvl 20 (Def > Atk)',

    // --- HOENN (Wurmple y Nincada) ---
    'silcoon': 'Lvl 7 (Random Personality)',
    'cascoon': 'Lvl 7 (Random Personality)',
    'beautifly': 'Lvl 10',
    'dustox': 'Lvl 10',
    'ninjask': 'Lvl 20',

    // --- SINNOH (Combee, Burmy, etc) ---
    'vespiquen': 'Lvl 21 (Female only)',
    'mothim': 'Lvl 20 (Male only)',
    'wormadam': 'Lvl 20 (Female only)',
    'mismeagius': 'Dusk Stone',
    'honchkrow': 'Dusk Stone',
    'weavile': 'Lvl Up + Hold Razor Claw (Night)',
    'gliscor': 'Lvl Up + Hold Razor Fang (Night)',
    'magnezone': 'Thunder Stone (or Magnetic Field)',
    'probopass': 'Thunder Stone (or Magnetic Field)',
    'leafeon': 'Leaf Stone (or Mossy Rock)',
    'glaceon': 'Ice Stone (or Icy Rock)',
    'gallade': 'Dawn Stone (Male only)',
    'froslass': 'Dawn Stone (Female only)',
    'rotom': 'Change appliance',
    
    // --- KALOS ---
    'pangoro': 'Lvl 32 + Dark-type in party',
    'malamar': 'Lvl 30 + Turn device upside down',
    'sylveon': 'Friendship + Fairy Move',
    'goodra': 'Lvl 50 (Rain)',
    'aurorus': 'Lvl 39 (Night)',
    'tyrantrum': 'Lvl 39 (Day)',

    // --- ALOLA (GEN 7) ---
    'persian-alola': 'Friendship (High)', 
    'raticate-alola': 'Lvl 20 (Night)',
    'raichu-alola': 'Thunder Stone (in Alola)',
    'sandslash-alola': 'Ice Stone',
    'ninetales-alola': 'Ice Stone',
    'marowak-alola': 'Lvl 28 (Night in Alola)',
    'exeggutor-alola': 'Leaf Stone (in Alola)',
    'vikavolt': 'Thunder Stone (or Magnetic Field)',
    'crabominable': 'Ice Stone (or Mt. Lanakila)',
    'salazzle': 'Lvl 33 (Female only)',
    'solgaleo': 'Lvl 53 (Sun / Sword)',
    'lunala': 'Lvl 53 (Moon / Shield)',

    // --- GALAR (GEN 8) ---
    'appletun': 'Use Sweet Apple',
    'flapple': 'Use Tart Apple',
    'slowbro-galar': 'Use Galarica Cuff',
    'slowking-galar': 'Use Galarica Wreath',
    'weezing-galar': 'Lvl 35 (in Galar)',
    'linoone-galar': 'Lvl 20 (Night)',
    'obstagoon': 'Lvl 35 (Night)',
    'perrserker': 'Lvl 28',
    'cursola': 'Lvl 38',
    'mr-mime-galar': 'Lvl Up (in Galar)', 
    'mr-rime': 'Lvl 42',
    'runerigus': '49+ DMG & Walk under Stone Arch',
    'sirfetchd': '3 Critical Hits in one battle',
    'frosmoth': 'Friendship (Night)',
    'alcremie': 'Spin holding Sweet',
    'darmanitan-galar-standard': 'Ice Stone',
    'darmanitan-galar-zen': 'Use Zen Mode',
    // Kubfu
    'urshifu-single-strike': 'Scroll of Darkness (Tower of Darkness)',
    'urshifu-rapid-strike': 'Scroll of Waters (Tower of Waters)',
    
    // --- HISUI (GEN 8) ---
    'electrode-hisui': 'Leaf Stone',
    'kleavor': 'Black Augurite',
    'ursaluna': 'Peat Block (Full Moon)',
    'basculegion': '294 Recoil DMG w/o fainting',
    'sneasler': 'Use Razor Claw (Day)',
    'overqwil': 'Use Barb Barrage 20 times (Strong Style)',
    'wyrdeer': 'Use Psyshield Bash 20 times (Agile Style)',
    'braviary-hisui': 'Lvl 54 (Hisui)',
    'sliggoo-hisui': 'Lvl 40 (Rain)',
    'goodra-hisui': 'Lvl 50 (Rain)',
    'avalugg-hisui': 'Lvl 37 (Hisui)',
    'decidueye-hisui': 'Lvl 34 (Hisui)',
    'typhlosion-hisui': 'Lvl 36 (Hisui)',
    'samurott-hisui': 'Lvl 36 (Hisui)',
    'lilligant-hisui': 'Sun Stone',

    // --- PALDEA (GEN 9) ---
    // Applin line
    'dipplin': 'Use Syrupy Apple',
    'hydrapple': 'Lvl Up knowing Dragon Cheer',
    
    // Poltchageist
    'sinistcha': 'Use Unremarkable or Masterpiece Teacup',

    // Duraludon
    'archaludon': 'Use Metal Alloy',

    'annihilape': 'Use Rage Fist 20 times',
    'kingambit': 'Defeat 3 Bisharp leaders',
    'dudunsparce': 'Lvl Up knowing Hyper Drill',
    'dudunsparce-two-segment': 'Lvl Up knowing Hyper Drill',
    'dudunsparce-three-segment': 'Lvl Up knowing Hyper Drill (Rare)',
    'farigiraf': 'Lvl Up knowing Twin Beam',
    'maushold': 'Lvl 25 (Battle)',
    'maushold-family-of-three': 'Lvl 25 (Rare)',
    'pawmot': 'Walk 1000 steps (Let\'s Go mode)',
    'brambleghast': 'Walk 1000 steps (Let\'s Go mode)',
    'rabsca': 'Walk 1000 steps (Let\'s Go mode)',
    'ceruledge': 'Malicious Armor',
    'armarouge': 'Auspicous Armor',
    'palafin': 'Lvl 38 (Multiplayer Union Circle)',
    'gholdengo': '999 Gimmighoul Coins',
  };

  static String getEvoNodeName(String base, String suffix) {
    if (base == 'dudunsparce') return 'dudunsparce-two-segment';
    if (base == 'maushold') return 'maushold-family-of-three';
    if (base == 'basculin' && suffix == '-hisui') return 'basculin-white-striped';
    if (base == 'yamask' && suffix == '-galar') return 'yamask-galar';
    if (base == 'darmanitan' && suffix == '-galar') return 'darmanitan-galar-standard';
    if (base == 'tauros' && suffix == '-paldea') return 'tauros-paldea-combat-breed';
    if (base == 'slowpoke' && suffix == '-galar') return 'slowpoke-galar';

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
    // 1. AISLAMIENTO MANAPHY / PHIONE
    if (base == 'manaphy' || base == 'phione') return [];
    
    final cName = currentName.toLowerCase();

    // 2. ROCKRUFF MULTIRAMA
    if (base == 'rockruff') {
      for (var e in evos) {
        final details = e['evolution_details'] as List;
        if (details.isEmpty) continue;
        final time = details.first['time_of_day']?.toString() ?? "";
        
        if (time == 'night') e['species']['name'] = 'lycanroc-midnight';
        else if (time == 'dusk' || (details.first['location'] == null && time == "")) e['species']['name'] = 'lycanroc-dusk';
        else e['species']['name'] = 'lycanroc-midday';
      }
      return evos; 
    }

    // --- LÓGICA ESPECIAL SLOWPOKE (Galar vs Kanto) ---
    if (base == 'slowpoke') {
       if (suffix == '-galar') {
         for (var e in evos) {
            String name = e['species']['name'];
            if (name == 'slowbro') e['species']['name'] = 'slowbro-galar';
            if (name == 'slowking') e['species']['name'] = 'slowking-galar';
         }
         return evos.where((e) => e['species']['name'].toString().contains('galar')).toList();
       } else {
         return evos.where((e) => !e['species']['name'].toString().contains('galar')).toList();
       }
    }

    // --- LÓGICA ESPECIAL ALOLA ---
    if (suffix == '-alola') {
       if (base == 'pikachu') {
         for (var e in evos) if (e['species']['name'] == 'raichu') e['species']['name'] = 'raichu-alola';
       }
       if (base == 'exeggcute') {
         for (var e in evos) if (e['species']['name'] == 'exeggutor') e['species']['name'] = 'exeggutor-alola';
       }
       if (base == 'cubone') {
         for (var e in evos) if (e['species']['name'] == 'marowak') e['species']['name'] = 'marowak-alola';
       }
    }

    // --- LÓGICA ESPECIAL GALAR ---
    if (suffix == '-galar') {
       if (base == 'koffing') {
         for (var e in evos) if (e['species']['name'] == 'weezing') e['species']['name'] = 'weezing-galar';
       }
       if (base == 'mime-jr') {
         for (var e in evos) if (e['species']['name'] == 'mr-mime') e['species']['name'] = 'mr-mime-galar';
       }
    }

    // 3. INYECCIÓN MELTAN
    if (base == 'meltan' && evos.isEmpty) {
      return [{
        'species': {'name': 'melmetal'},
        'evolution_details': [{'trigger': {'name': 'pokemon-go'}}],
        'evolves_to': []
      }];
    }

    return evos.where((e) {
      String name = e['species']['name'].toLowerCase();

      // 4. FILTROS DE RAMAS
      if (base == 'yamask') {
        return suffix == '-galar' ? name == 'runerigus' : name == 'cofagrigus';
      }
      
      // Split Scyther / Kleavor
      if (base == 'scyther') return suffix == '-hisui' ? name == 'kleavor' : name == 'scizor';
      // Split Goomy
      if (base == 'goomy') return suffix == '-hisui' ? name == 'sliggoo' : name == 'sliggoo'; 
      // Split Dartrix
      if (base == 'dartrix') return suffix == '-hisui' ? name == 'decidueye' : name == 'decidueye';
      // Split Quilava
      if (base == 'quilava') return suffix == '-hisui' ? name == 'typhlosion' : name == 'typhlosion';
      // Split Dewott
      if (base == 'dewott') return suffix == '-hisui' ? name == 'samurott' : name == 'samurott';
      // Split Petilil
      if (base == 'petilil') return suffix == '-hisui' ? name == 'lilligant' : name == 'lilligant';
      // Split Rufflet
      if (base == 'rufflet') return suffix == '-hisui' ? name == 'braviary' : name == 'braviary';
      // Split Bergmite
      if (base == 'bergmite') return suffix == '-hisui' ? name == 'avalugg' : name == 'avalugg';

      if (base == 'basculin') return cName.contains('white-striped') && name == 'basculegion';
      if (base == 'wooper') return suffix == '-paldea' ? name == 'clodsire' : name == 'quagsire';
      if (base == 'sneasel') return suffix == '-hisui' ? name == 'sneasler' : name == 'weavile';
      if (base == 'qwilfish') return suffix == '-hisui' && name == 'overqwil';

      // Permitir evoluciones especiales nuevas
      if (['melmetal', 'ursaluna', 'wyrdeer', 'kleavor', 'annihilape', 'farigiraf', 'dudunsparce', 
           'kingambit', 'basculegion', 'runerigus', 'overqwil', 'archaludon', 'dipplin', 
           'hydrapple', 'pawmot', 'maushold', 'brambleghast', 'rabsca', 'palafin', 
           'gholdengo', 'sinistcha'].contains(name)) return true;

      // Si tiene sufijo galar/hisui/paldea, debe pasar
      if (name.contains('-galar') || name.contains('galar')) return true;
      if (name.contains('-hisui')) return true;
      if (name.contains('-paldea')) return true;
      if (name.contains('-alola')) return true;

      if (suffix == '-galar') return PokeConstants.galarianEvolutions.contains(name) || PokeConstants.galarianForms.contains(name);
      if (suffix == '-hisui') return PokeConstants.hisuiLine.contains(name);
      if (suffix == '-paldea') return PokeConstants.paldeaLine.contains(name);
      
      return !PokeConstants.galarianEvolutions.contains(name) && !PokeConstants.hisuianEvolutions.contains(name) && 
             name != 'clodsire' && name != 'manaphy' && name != 'phione' && name != 'runerigus';
    }).toList();
  }

  static String formatEvoDetails(List details, String to, String currentSuffix) {
    if (details.isEmpty) return "";
    String target = to.toLowerCase();

    // 1. CHECK MANUAL: Prioridad absoluta al mapa manual
    if (_manualOverrides.containsKey(target)) {
      return _manualOverrides[target]!;
    }
    // Caso especial para formas regionales cuyo "target" en la API no tiene sufijo
    if (currentSuffix.isNotEmpty) {
      final overrideKey = "$target$currentSuffix"; // ej: slowbro-galar
      if (_manualOverrides.containsKey(overrideKey)) {
        return _manualOverrides[overrideKey]!;
      }
    }

    // 2. SELECCIÓN INTELIGENTE DE DETALLES
    Map<String, dynamic> selectedDetail = details.first; 

    if (details.length > 1) {
      if (currentSuffix == '-alola') {
        var alolaDetail = details.firstWhere((d) {
          final item = d['item']?['name'] ?? '';
          final time = d['time_of_day']?.toString() ?? '';
          return item == 'ice-stone' || item == 'thunder-stone' || time == 'night';
        }, orElse: () => null);
        if (alolaDetail != null) selectedDetail = alolaDetail;
      } else if (currentSuffix == '-galar') {
        var galarDetail = details.firstWhere((d) {
           final item = d['item']?['name'] ?? '';
           return item.contains('galarica') || item == 'ice-stone';
        }, orElse: () => null);
        if (galarDetail != null) selectedDetail = galarDetail;
      } else {
        var kantoDetail = details.firstWhere((d) {
           final item = d['item']?['name'] ?? '';
           return item != 'ice-stone' && !item.contains('galarica'); 
        }, orElse: () => details.first);
        selectedDetail = kantoDetail;
      }
    }

    // Lógica para Gallade/Froslass (Género)
    if (target.contains('gallade')) {
       var d = details.firstWhere((d) => d['gender'] == 2, orElse: () => selectedDetail);
       selectedDetail = d;
    }
    if (target.contains('froslass')) {
       var d = details.firstWhere((d) => d['gender'] == 1, orElse: () => selectedDetail);
       selectedDetail = d;
    }

    // 3. PARSEO ESTÁNDAR
    final trigger = selectedDetail['trigger']['name']?.toString();
    final String timeOfDay = selectedDetail['time_of_day']?.toString() ?? "";
    final heldItem = selectedDetail['held_item'];
    final item = selectedDetail['item'];
    final knownMove = selectedDetail['known_move'];
    final minLevel = selectedDetail['min_level'];
    final minHappy = selectedDetail['min_happiness'];
    final minAffection = selectedDetail['min_affection'];
    final location = selectedDetail['location'];

    // Trades
    if (trigger == 'trade') {
      if (heldItem != null) return "Trade + ${heldItem['name'].toString().cleanName}";
      if (target.contains('accelgor') || target.contains('escavalier')) return "Trade for Karrablast/Shelmet";
      return "Trade";
    }

    // Items
    if (item != null) return item['name'].toString().cleanName;

    // Level Up conditions
    if (trigger == 'level-up') {
      List<String> conditions = [];

      if (minLevel != null) conditions.add("Lvl $minLevel");
      else if (minHappy == null && knownMove == null && location == null && minAffection == null) conditions.add("Lvl Up");

      if (minHappy != null) conditions.add("Friendship");
      if (minAffection != null) conditions.add("Affection");
      
      // SOLUCIÓN DEL ERROR DEL PANTALLAZO:
      if (timeOfDay.isNotEmpty) conditions.add("(${timeOfDay.capitalize})");
      
      if (location != null) conditions.add("near ${location['name'].toString().cleanName}");
      if (heldItem != null) conditions.add("holding ${heldItem['name'].toString().cleanName}");
      if (knownMove != null) conditions.add("knows ${knownMove['name'].toString().cleanName}");
      
      // Casos Tyrogue
      if (target.contains('hitmonlee')) conditions.add("(Atk > Def)");
      if (target.contains('hitmonchan')) conditions.add("(Def > Atk)");
      if (target.contains('hitmontop')) conditions.add("(Atk = Def)");
      
      if (conditions.isEmpty) return "Lvl Up";
      return conditions.join(" ");
    }
    
    // Shedinja fallback
    if (target == 'shedinja') return "Lvl 20 (Empty Slot & Poké Ball)";

    return trigger.toString().cleanName.capitalize;
  }
}