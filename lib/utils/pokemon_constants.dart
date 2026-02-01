class PokeConstants {
  // --- TIPOS ELEMENTALES ---
  // Lista maestra usada para generar los chips de filtro y la tabla de debilidades.
  static const List<String> allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting', 
    'poison', 'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost', 
    'dragon', 'dark', 'steel', 'fairy'
  ];

  // --- FORMAS REGIONALES (Variantes) ---
  // Listas de nombres de Pokémon que poseen una variante en dicha región.
  // Se usan para saber cuándo agregar sufijos (ej: '-alola', '-galar') a las peticiones de la API.
  static const List<String> alolanForms = ['rattata', 'raticate', 'raichu', 'sandshrew', 'sandslash', 'vulpix', 'ninetales', 'diglett', 'dugtrio', 'meowth', 'persian', 'geodude', 'graveler', 'golem', 'grimer', 'muk', 'exeggutor', 'marowak'];
  static const List<String> galarianForms = ['meowth', 'ponyta', 'rapidash', 'slowpoke', 'slowbro', 'farfetchd', 'weezing', 'mr-mime', 'articuno', 'zapdos', 'moltres', 'slowking', 'corsola', 'zigzagoon', 'linoone', 'darumaka', 'darmanitan', 'yamask', 'stunfisk'];
  static const List<String> hisuianForms = ['growlithe', 'arcanine', 'voltorb', 'electrode', 'typhlosion', 'samurott', 'decidueye', 'qwilfish', 'sneasel', 'lilligant', 'zorua', 'zoroark', 'braviary', 'sliggoo', 'goodra', 'avalugg', 'basculin'];
  static const List<String> paldeanForms = ['wooper', 'tauros'];

  // --- EVOLUCIONES REGIONALES (Nuevas Especies) ---
  // Pokémon que son especies totalmente nuevas (tienen su propio ID en la Pokedex),
  // no solo variantes de una existente. Ej: Obstagoon es la evo de Linoone Galar.
  static const List<String> galarianEvolutions = ['perrserker', 'mr-rime', 'cursola', 'obstagoon', 'sirfetchd', 'runerigus'];
  static const List<String> hisuianEvolutions = ['wyrdeer', 'kleavor', 'ursaluna', 'basculegion', 'sneasler', 'overqwil'];
  static const List<String> paldeanEvolutions = ['clodsire', 'dudunsparce', 'dudunsparce-three-segment'];

  // --- GRUPOS DE FILTRADO PARA EVOLUCIONES ---
  // Listas auxiliares que agrupan pre-evoluciones y evoluciones regionales.
  // Ayudan al EvolutionHelper a decidir qué ramas mostrar. Por ejemplo, 'hisuiLine' asegura
  // que si vemos a Goomy en Hisui, muestre a Sliggoo-Hisui y Goodra-Hisui.
  static const List<String> hisuiPreEvos = ['rowlet', 'dartrix', 'cyndaquil', 'quilava', 'oshawott', 'dewott', 'petilil', 'rufflet', 'goomy', 'bergmite', 'zorua', 'stantler', 'scyther', 'ursaring'];
  static const List<String> hisuiLine = [...hisuianForms, ...hisuianEvolutions, ...hisuiPreEvos];
  static const List<String> paldeaLine = [...paldeanForms, ...paldeanEvolutions, 'dunsparce'];
  
  // Lista de Pokémon base cuyas ramas evolutivas divergen totalmente según la región.
  static const List<String> branchReplacements = ['meowth', 'sneasel', 'qwilfish', 'yamask', 'farfetchd', 'mr-mime', 'corsola', 'wooper', 'ponyta', 'darumaka', 'zigzagoon', 'linoone', 'pikachu', 'exeggcute', 'cubone'];

  // --- TRADUCCIONES DE MÉTODOS EVOLUTIVOS ---
  // Mapea una clave interna (ej: 'alola:rattata') a una clave de traducción en los archivos JSON.
  // Permite mostrar textos específicos como "Alola: Level 20 Night" en lugar del genérico.
  static const Map<String, String> regionalEvolutionOverrides = {
    'alola:rattata': 'evolutions.override_alola_rattata',
    'alola:sandshrew': 'evolutions.override_alola_sandshrew',
    'alola:vulpix': 'evolutions.override_alola_vulpix',
    'alola:meowth': 'evolutions.override_alola_meowth',
    'alola:geodude': 'evolutions.override_alola_geodude',
    'alola:graveler': 'evolutions.override_alola_graveler',
    'alola:grimer': 'evolutions.override_alola_grimer',
    'alola:exeggcute': 'evolutions.override_alola_exeggcute',
    'alola:cubone': 'evolutions.override_alola_cubone',
    'galar:meowth': 'evolutions.override_galar_meowth',
    'galar:ponyta': 'evolutions.override_galar_ponyta',
    'galar:farfetchd': 'evolutions.override_galar_farfetchd',
    'galar:corsola': 'evolutions.override_galar_corsola',
    'galar:zigzagoon': 'evolutions.override_galar_zigzagoon',
    'galar:linoone': 'evolutions.override_galar_linoone',
    'galar:darumaka': 'evolutions.override_galar_darumaka',
    'galar:yamask': 'evolutions.override_galar_yamask',
    'galar:slowpoke>slowbro': 'evolutions.override_galar_slowbro',
    'galar:slowpoke>slowking': 'evolutions.override_galar_slowking',
    'hisui:growlithe': 'evolutions.override_hisui_growlithe',
    'hisui:voltorb': 'evolutions.override_hisui_voltorb',
    'hisui:qwilfish': 'evolutions.override_hisui_qwilfish',
    'hisui:sneasel': 'evolutions.override_hisui_sneasel',
    'hisui:basculin': 'evolutions.override_hisui_basculin',
    'hisui:scyther': 'evolutions.override_hisui_scyther',
    'hisui:petilil': 'evolutions.override_hisui_petilil',
    'hisui:goomy': 'evolutions.override_hisui_goomy',
    'hisui:rufflet': 'evolutions.override_hisui_rufflet',
    'hisui:bergmite': 'evolutions.override_hisui_bergmite',
    'hisui:stantler': 'evolutions.override_hisui_stantler',
    'paldea:wooper': 'evolutions.override_paldea_wooper',
    'hisui:ursaring': 'evolutions.override_hisui_ursaring',
    'paldea:dunsparce': 'evolutions.override_paldea_dunsparce',
  };
}