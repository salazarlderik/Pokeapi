import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'utils/type_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'package:easy_localization/easy_localization.dart';

/// Muestra la vista detallada de un solo Pokémon, incluyendo estadísticas,
/// habilidades, formas y cadena evolutiva.
class PokemonDetailScreen extends StatefulWidget {
  /// Los datos del endpoint '/pokemon/{name}'
  final Map<String, dynamic> pokemon;
  
  /// Los datos del endpoint '/pokemon-species/{name}'
  final Map<String, dynamic> species;

  const PokemonDetailScreen({
    Key? key,
    required this.pokemon,
    required this.species,
  }) : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  /// Instancia del servicio para realizar llamadas a la API.
  final ApiService _apiService = ApiService();

  // --- Banderas de estado de carga ---
  bool _isLoadingAbilities = true;
  bool _isLoadingTypeDefenses = true;
  bool _isLoadingVarietyTypes = true;
  bool _isLoadingEvolution = true;

  // --- Datos de estado ---
  /// Almacena las descripciones de las habilidades (Nombre -> Descripción).
  Map<String, String> _abilityDetails = {};
  /// Almacena los multiplicadores de daño por tipo (Tipo -> Multiplicador).
  Map<String, double> _typeEffectiveness = {};
  /// Lista de todas las formas/variedades del Pokémon (para el selector de formas).
  List<dynamic> _varieties = [];
  /// Datos del Pokémon actualmente seleccionado (puede cambiar con el selector de formas).
  late Map<String, dynamic> _currentPokemonData;
  /// Nombre de la forma/variedAD actualmente seleccionada.
  late String _currentVarietyName;
  /// Nombre del Pokémon actual, usado para la lógica de filtrado de evolución.
  late String _currentPokemonNameForEvo;
  /// Sufijo regional (ej. '-alola'), usado para filtrar la evolución.
  late String _regionSuffixForEvo;
  /// Almacena el primer tipo de cada variedad (para colorear los chips de formas).
  Map<String, String> _varietyFirstTypes = {};
  /// Almacena el JSON completo de la cadena evolutiva.
  Map<String, dynamic>? _evolutionChainData;

  /// Rastreador para detectar cambios en el idioma de la app.
  Locale? _previousLocale;

  /// Mapa de 'override' para métodos de evolución complejos o regionales.
  /// Usado por [_formatEvolutionDetails] para mostrar texto personalizado.
  static const Map<String, String> _regionalEvolutionOverrides = {
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

  /// Listas de constantes para ayudar a la lógica de filtrado de evoluciones.
  static const List<String> _alolanForms = ['rattata', 'raticate', 'raichu', 'sandshrew', 'sandslash', 'vulpix', 'ninetales', 'diglett', 'dugtrio', 'meowth', 'persian', 'geodude', 'graveler', 'golem', 'grimer', 'muk', 'exeggutor', 'marowak'];
  static const List<String> _galarianForms = ['meowth', 'ponyta', 'rapidash', 'slowpoke', 'slowbro', 'farfetchd', 'weezing', 'mr-mime', 'articuno', 'zapdos', 'moltres', 'slowking', 'corsola', 'zigzagoon', 'linoone', 'darumaka', 'darmanitan', 'yamask', 'stunfisk'];
  static const List<String> _hisuianForms = ['growlithe', 'arcanine', 'voltorb', 'electrode', 'typhlosion', 'samurott', 'decidueye', 'qwilfish', 'sneasel', 'lilligant', 'zorua', 'zoroark', 'braviary', 'sliggoo', 'goodra', 'avalugg', 'basculin'];
  static const List<String> _paldeanForms = ['wooper', 'tauros'];
  static const List<String> _galarianEvolutions = ['perrserker', 'mr-rime', 'cursola', 'obstagoon', 'sirfetchd', 'runerigus'];
  static const List<String> _hisuianEvolutions = ['wyrdeer', 'kleavor', 'ursaluna', 'basculegion', 'sneasler', 'overqwil'];
  static const List<String> _paldeanEvolutions = ['clodsire', 'dudunsparce', 'dudunsparce-three-segment'];
  static const List<String> _hisuiPreEvos = [ 'rowlet', 'dartrix', 'cyndaquil', 'quilava', 'oshawott', 'dewott', 'petilil', 'rufflet', 'goomy', 'bergmite', 'zorua', 'stantler', 'scyther', 'ursaring', ];
  static const List<String> _hisuiLine = [..._hisuianForms, ..._hisuianEvolutions, ..._hisuiPreEvos];
  static const List<String> _paldeaLine = [..._paldeanForms, ..._paldeanEvolutions, 'dunsparce'];
  static const List<String> _branchReplacements = [ 'meowth', 'sneasel', 'qwilfish', 'yamask', 'farfetchd', 'mr-mime', 'corsola', 'wooper', 'ponyta', 'darumaka', 'zigzagoon', 'linoone', 'pikachu', 'exeggcute', 'cubone', ];
  
  /// Lista completa de todos los tipos para la tabla de defensas.
  final List<String> _allTypes = ['normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'];

  @override
  void initState() {
    super.initState();
    // Inicializa el estado con los datos del Pokémon actual
    _currentPokemonData = widget.pokemon;
    _varieties = widget.species['varieties'] ?? [];
    _currentVarietyName = _currentPokemonData['name'];
    _currentPokemonNameForEvo = widget.pokemon['name'];
    _regionSuffixForEvo = _getRegionSuffix();
    
    // Carga la cadena evolutiva (no depende del idioma)
    _fetchEvolutionChain();
    
    // NOTA: _loadAllDataForCurrentForm() se llama en didChangeDependencies
    // para asegurar que el 'context.locale' esté disponible.
  }

  /// Se dispara cuando las dependencias (como `context.locale`) cambian.
  /// Usado para recargar datos dependientes del idioma (habilidades)
  /// cuando el usuario presiona el botón de idioma.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final currentLocale = context.locale;
    
    // Si el idioma cambió (o es la primera carga), recarga los datos.
    if (currentLocale != _previousLocale) {
      print("Locale changed to $currentLocale. Refetching data.");
      _previousLocale = currentLocale;
      
      // Carga datos que dependen del idioma (habilidades) y de la forma (tipos).
      _loadAllDataForCurrentForm(); 
    }
  }

  /// Determina el sufijo regional (ej. '-alola') del Pokémon actual.
  String _getRegionSuffix() {
    String currentName = _currentPokemonNameForEvo;
    String speciesName = widget.species['name'];
    if (currentName.contains('-alola')) return '-alola';
    if (currentName.contains('-galar')) return '-galar';
    if (currentName.contains('-hisui')) return '-hisui';
    if (currentName.contains('-paldea')) return '-paldea';
    if (currentName.startsWith('dudunsparce')) return '-paldea';
    
    // Verifica si es una evolución regional (ej. Obstagoon)
    if (_galarianEvolutions.contains(speciesName)) return '-galar';
    if (_hisuianEvolutions.contains(speciesName)) return '-hisui';
    if (_paldeanEvolutions.contains(speciesName)) return '-paldea';
    return ""; // Sin sufijo
  }

  /// Carga todos los datos asíncronos para la forma actualmente seleccionada.
  /// Se llama al inicio y cada vez que cambia el idioma o la forma.
  Future<void> _loadAllDataForCurrentForm() async {
    if (!mounted) return;
    
    // Obtiene el código de idioma (ej. 'es') del contexto.
    final currentLanguageCode = context.locale.languageCode;
    
    setState(() { 
      _isLoadingAbilities = true; 
      _isLoadingTypeDefenses = true; 
      _isLoadingVarietyTypes = true; 
    });
    
    // Ejecuta todas las cargas en paralelo
    await Future.wait([
      _fetchAbilityDetails(_currentPokemonData, currentLanguageCode),
      _fetchTypeEffectiveness(_currentPokemonData), 
      _fetchVarietyTypes(), 
    ]);
  }

  /// Obtiene y almacena el JSON de la cadena evolutiva.
  Future<void> _fetchEvolutionChain() async {
    setState(() { _isLoadingEvolution = true; });
    
    // Lógica especial para encontrar la especie base correcta
    String speciesNameForEvo = widget.species['name']; 
    if (speciesNameForEvo == 'slowpoke' && widget.pokemon['name'].contains('-galar')) { speciesNameForEvo = 'slowpoke'; }
    if (speciesNameForEvo == 'ursaluna') { speciesNameForEvo = 'teddiursa'; }
    if (speciesNameForEvo.startsWith('dudunsparce')) {
      speciesNameForEvo = 'dunsparce';
    }
    
    try {
      final speciesData = await _apiService.fetchPokemonSpecies(speciesNameForEvo);
      final evoChainUrl = speciesData['evolution_chain']['url'] as String;
      final data = await _apiService.fetchEvolutionChain(evoChainUrl);
      if (mounted) { setState(() { _evolutionChainData = data; _isLoadingEvolution = false; }); }
    } catch (e) {
      print('Error fetching evolution chain: $e');
      if (mounted) { setState(() { _isLoadingEvolution = false; }); }
    }
  }

  /// Obtiene el primer tipo de todas las variedades listadas.
  /// Usado para colorear los chips en el [_buildFormSelector].
  Future<void> _fetchVarietyTypes() async {
    Map<String, String> newVarietyFirstTypes = {};
    List<Future<void>> typeFetchFutures = [];
    
    for (var variety in _varieties) {
      final String formName = variety['pokemon']['name'];
      // Solo busca si es una forma diferente y no la tenemos ya
      if (formName != widget.species['name'] && !_varietyFirstTypes.containsKey(formName)) {
        typeFetchFutures.add(() async {
          try {
            final pokemonDetails = await _apiService.fetchPokemonDetails(formName);
            final types = (pokemonDetails['types'] as List<dynamic>).map<String>((typeInfo) => typeInfo['type']['name'] as String).toList();
            if (types.isNotEmpty) { newVarietyFirstTypes[formName] = types.first; }
          } catch (e) { print('Error fetching types for variety $formName: $e'); }
        }());
      }
    }
    
    await Future.wait(typeFetchFutures);
    if (mounted) { setState(() { _varietyFirstTypes.addAll(newVarietyFirstTypes); _isLoadingVarietyTypes = false; }); }
  }

  /// Obtiene los detalles de las habilidades para el Pokémon actual.
  /// Pasa el [languageCode] a [_fetchSingleAbility] para la traducción.
  Future<void> _fetchAbilityDetails(Map<String, dynamic> pokemonData, String languageCode) async {
    final abilities = (pokemonData['abilities'] as List<dynamic>);
    Map<String, String> newAbilityDetails = {};
    List<Future<Map<String, String?>>> futures = [];
    
    for (var abilityInfo in abilities) {
      final abilityUrl = abilityInfo['ability']['url'] as String;
      final abilityName = abilityInfo['ability']['name'] as String;
      futures.add(_fetchSingleAbility(abilityUrl, abilityName, languageCode));
    }
    
    try {
      final results = await Future.wait(futures);
      for (var res in results) { 
        newAbilityDetails[res['name']!] = res['effect'] ?? 'abilities_fallback.no_desc'.tr(); 
      }
    } catch (e) { print('Error fetching abilities: $e'); }
    
    if (mounted) { setState(() { _abilityDetails = newAbilityDetails; _isLoadingAbilities = false; }); }
  }

  /// Obtiene la descripción traducida de una sola habilidad.
  ///
  /// Esta función implementa una lógica compleja para obtener traducciones de la PokeAPI:
  /// 1. Usa `flavor_text_entries` (descripciones de Pokédex) en lugar de `effect_entries` (que no están traducidas).
  /// 2. Pasa una cabecera `Accept-Language` para pedirle a la API que filtre por idioma.
  /// 3. Añade un "cache buster" (`?cb=...`) a la URL para evitar que un caché de red
  ///    devuelva la versión en inglés.
  Future<Map<String, String?>> _fetchSingleAbility(String url, String name, String languageCode) async {
    try {
      // 1. Crea una URI única (cache-buster) para evitar el caché de la API
      final uri = Uri.parse(url);
      final Map<String, String> queryParams = Map.from(uri.queryParameters);
      queryParams['cb'] = DateTime.now().millisecondsSinceEpoch.toString();
      final newUri = uri.replace(queryParameters: queryParams);

      // 2. Realiza la petición HTTP forzando el idioma en la cabecera
      final response = await http.get(
        newUri,
        headers: {
          'Accept-Language': languageCode
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 3. Busca en las 'flavor_text_entries' (descripciones de Pokédex)
        final entries = data['flavor_text_entries'] as List<dynamic>;

        // 4. Intenta encontrar la descripción en el idioma solicitado (ej. 'es')
        var entry = entries.firstWhere(
          (e) => e['language']['name'] == languageCode,
          orElse: () => null,
        );

        // 5. Si falla, hace un fallback a inglés ('en')
        if (entry == null) {
          print("No se encontró 'flavor_text' en '$languageCode'. Probando 'en'.");
          entry = entries.firstWhere(
            (e) => e['language']['name'] == 'en',
            orElse: () => null,
          );
        }

        // 6. Devuelve la descripción (si se encontró)
        if (entry != null) {
          // Limpia los saltos de línea de la descripción
          String description = (entry['flavor_text'] as String).replaceAll('\n', ' ');
          return {'name': name, 'effect': description};
        } else {
          print("FATAL: No se encontró 'flavor_text' en $name");
          return {'name': name, 'effect': null}; 
        }
      }
    } catch (e) {
      print('Error en la red buscando $name: $e');
    }
    
    // Fallback si la petición de red falla
    return {'name': name, 'effect': 'abilities_fallback.error'.tr()};
  }

  /// Obtiene y calcula las debilidades y resistencias del tipo del Pokémon.
  Future<void> _fetchTypeEffectiveness(Map<String, dynamic> pokemonData) async {
    if (!mounted) return;
    
    // Inicializa el mapa con todos los tipos en x1
    Map<String, double> effectivenessMap = { for (var type in _allTypes) type: 1.0 };
    
    final types = (pokemonData['types'] as List<dynamic>).map<String>((typeInfo) => typeInfo['type']['name'] as String).toList();
    List<Future<http.Response>> typeFutures = [];
    
    // Pide los datos de cada tipo del Pokémon
    for (var typeName in types) { 
      typeFutures.add(http.get(Uri.parse('https://pokeapi.co/api/v2/type/$typeName'))); 
    }
    
    try {
      final typeResponses = await Future.wait(typeFutures);
      
      // Itera sobre las respuestas (ej. una para 'planta', una para 'veneno')
      for (var response in typeResponses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['damage_relations'];
          // Multiplica los valores del mapa
          for (var type in data['double_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 2.0; }
          for (var type in data['half_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.5; }
          for (var type in data['no_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.0; }
        }
      }
      
      if (mounted) { setState(() { _typeEffectiveness = effectivenessMap; _isLoadingTypeDefenses = false; }); }
    } catch (e) {
      print('Error fetching type defenses: $e');
      if (mounted) { setState(() { _isLoadingTypeDefenses = false; }); }
    }
  }

  /// Se dispara cuando el usuario selecciona una forma (Mega, Gmax, Alola)
  /// del [_buildFormSelector].
  Future<void> _onFormChanged(String? newFormName) async {
    if (newFormName == null || newFormName == _currentVarietyName) return;
    
    try {
      // Busca los datos de la nueva forma
      final newPokemonData = await _apiService.fetchPokemonDetails(newFormName);
      if (mounted) {
        // Actualiza el estado para reflejar la nueva forma
        setState(() {
          _currentPokemonData = newPokemonData;
          _currentVarietyName = newFormName;
          // Actualiza el nombre para el filtro de evolución (ej. 'slowpoke-galar')
          _currentPokemonNameForEvo = newFormName; 
          _regionSuffixForEvo = _getRegionSuffix();
        });
        
        // Vuelve a cargar todos los datos que dependen de la forma
        // (habilidades, defensas) y recarga la cadena de evolución (para Galar-Slowpoke).
        await Future.wait([
          _loadAllDataForCurrentForm(),
          _fetchEvolutionChain(), 
        ]);
      }
    } catch (e) { print('Error changing form: $e'); }
  }

  /// Navega a la pantalla de detalles de un Pokémon diferente.
  /// Se usa al tocar un Pokémon en la cadena evolutiva.
  Future<void> _navigateToPokemon(String pokemonName) async {
    if (pokemonName == _currentPokemonNameForEvo) return;
    
    // Muestra un loader
    showDialog( context: context, barrierDismissible: false, builder: (context) => Center(child: CircularProgressIndicator()), );
    
    try {
      // Carga los dos endpoints necesarios para la nueva pantalla
      final species = await _apiService.fetchPokemonSpecies(pokemonName);
      final pokemon = await _apiService.fetchPokemonDetails(pokemonName);
      
      Navigator.of(context, rootNavigator: true).pop(); // Cierra el loader
      
      // Reemplaza la pantalla actual por la nueva
      Navigator.pushReplacement( 
        context, 
        MaterialPageRoute( 
          builder: (context) => PokemonDetailScreen( pokemon: pokemon, species: species, ), 
        ), 
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Cierra el loader
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('error_load_pokemon'.tr(args: [pokemonName]))), );
      print('Error navigating to $pokemonName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Extracción de Datos para el Build ---
    final String heroId = widget.species['id'].toString();
    final String name = _currentPokemonData['name'];
    final sprites = _currentPokemonData['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork = otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final String imageUrl = officialArtwork?['front_default'] as String? ?? sprites['front_default'] as String? ?? '';
    final types = (_currentPokemonData['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final abilityNames = (_currentPokemonData['abilities'] as List<dynamic>).map<String>((ability) => ability['ability']['name'] as String).toList();
    final int height = _currentPokemonData['height'];
    final int weight = _currentPokemonData['weight'];
    final stats = (_currentPokemonData['stats'] as List<dynamic>);
    final mainColor = types.isNotEmpty ? getTypeColor(types.first) : Colors.grey;

    // --- Construcción del UI ---
    return Scaffold(
      appBar: AppBar(
        title: Text(name[0].toUpperCase() + name.substring(1)), 
        backgroundColor: mainColor,
        actions: [
          /// Botón para cambiar de idioma
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              if (context.locale == Locale('en')) {
                context.setLocale(Locale('es'));
              } else {
                context.setLocale(Locale('en'));
              }
            },
          ),
        ],
      ),
      body: Container(
        /// Fondo degradado sutil basado en el color del tipo
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.10)])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Sección: Selector de Formas
              _isLoadingVarietyTypes ? Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) : _buildFormSelector(mainColor),
              
              /// Sección: Imagen Principal
              Hero(
                tag: 'pokemon-$heroId',
                child: imageUrl.isEmpty 
                  ? Icon(Icons.image_not_supported, size: 200, color: Colors.grey) 
                  : Image.network( 
                      imageUrl, 
                      width: 250, height: 250, fit: BoxFit.contain, 
                      loadingBuilder: (c, ch, p) => p == null ? ch : Center(child: SizedBox(height: 250, child: CircularProgressIndicator())), 
                      errorBuilder: (c, e, s) => Icon(Icons.error, size: 200, color: Colors.red) 
                    )
              ),
              const SizedBox(height: 16),
              
              /// Sección: Nombre y Tipos
              Text(name.toUpperCase(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 8.0, runSpacing: 4.0, children: types.map((type) => _buildTypeChip(type)).toList()),
              const SizedBox(height: 24),
              
              /// Sección: Tarjeta de ID/Peso/Altura
              _buildStatsCard(heroId, weight, height),
              const SizedBox(height: 24),
              
              /// Sección: Estadísticas Base
              Text('headers.base_stats'.tr(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: stats.map((stat) => _buildStatBar(stat)).toList()))),
              const SizedBox(height: 24),
              
              /// Sección: Cadena Evolutiva
              Text('headers.evolution_chain'.tr(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildEvolutionSection(),
              const SizedBox(height: 24),
              
              /// Sección: Defensas de Tipo
              Text('headers.type_defenses'.tr(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: _isLoadingTypeDefenses 
                  ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator())) 
                  : Table( 
                      border: TableBorder.all( color: Colors.grey.shade300, width: 1.0, ), 
                      children: [ 
                        _buildTypeRow(_allTypes.sublist(0, 9)), 
                        _buildTypeRow(_allTypes.sublist(9, 18)), 
                      ], 
                    ),
              ),
              const SizedBox(height: 24),
              
              /// Sección: Habilidades
              Text('headers.abilities'.tr(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isLoadingAbilities 
                ? const Center(child: CircularProgressIndicator()) 
                : ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: abilityNames.length,
                    itemBuilder: (context, index) {
                      final abilityName = abilityNames[index];
                      // La descripción se obtiene del mapa _abilityDetails (ya traducido)
                      final description = _abilityDetails[abilityName] ?? 'abilities_fallback.no_desc'.tr();
                      return Card(
                        elevation: 2, margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(abilityName[0].toUpperCase() + abilityName.substring(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          subtitle: Text(description.replaceAll('\n', ' '), style: TextStyle(color: Colors.grey[700])),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una fila [TableRow] para la tabla de defensas de tipo.
  TableRow _buildTypeRow(List<String> types) {
    return TableRow(
      children: types.map((type) {
        final double multiplier = _typeEffectiveness[type] ?? 1.0;
        return _buildTypeEffectivenessItem(type, multiplier);
      }).toList(),
    );
  }

  /// Construye el selector horizontal de formas (Mega, Alola, etc.).
  Widget _buildFormSelector(Color mainColor) {
    if (_varieties.length <= 1) { return SizedBox.shrink(); } // No mostrar si solo hay 1 forma
    
    final Color gmaxColor = Colors.red[700]!;
    final Color primalColor = Colors.deepOrange[800]!;
    
    List<Widget> chips = _varieties.map((variety) {
      final String formName = variety['pokemon']['name'];
      
      // Formatea el nombre para mostrar (ej. 'charizard-mega-x' -> 'Mega X')
      final String formattedName = formName.replaceAll('-', ' ').replaceFirst(widget.species['name'], '').trim().split(' ').where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      final String displayName = formattedName.isEmpty ? 'forms.base'.tr() : formattedName;
      
      final bool isSelected = formName == _currentVarietyName;
      
      // --- Lógica de Estilo de Chips ---
      Color chipBackgroundColor = Colors.white;
      Color chipBorderColor = Colors.grey.shade300;
      Color chipTextColor = Colors.black87;
      Widget? chipAvatar;
      Widget? finalChipWidget;

      if (displayName.contains('Mega')) {
        // Chip especial para Megaevoluciones
        final keystoneGradient = LinearGradient( colors: [ Color(0xFF63D8FF), Color(0xFF8B55FF), Color(0xFFFFC75F), Color(0xFFFF5656) ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
        finalChipWidget = Container(
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration( borderRadius: BorderRadius.circular(12), gradient: keystoneGradient, boxShadow: isSelected ? [ BoxShadow( color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 4), ), ] : null, ),
          padding: const EdgeInsets.all(2.0),
          child: Container( 
            decoration: BoxDecoration( color: isSelected ? Color(0xFF282828) : Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(10.0), ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar( radius: 12, backgroundColor: Colors.transparent, child: Image.asset('assets/images/piedra_activadora.png'), ),
                const SizedBox(width: 8),
                Text( displayName, style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, ), ),
              ],
            ),
          ),
        );
      } else {
        // Chips estándar
        if (displayName.contains('Gmax')) {
          Color themeColor = gmaxColor;
          chipAvatar = CircleAvatar( radius: 12, backgroundColor: Colors.transparent, child: Image.asset('assets/images/gmax_logo.png'), );
          chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
          chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        } else if (displayName.contains('Alola') || displayName.contains('Galar') || displayName.contains('Hisui')) {
          // Usa el tipo de la forma regional para el color
          final String? firstType = _varietyFirstTypes[formName];
          if (firstType != null) {
            final regionalTypeColor = getTypeColor(firstType);
            chipBackgroundColor = isSelected ? regionalTypeColor : regionalTypeColor.withOpacity(0.2);
            chipBorderColor = isSelected ? regionalTypeColor : regionalTypeColor.withOpacity(0.5);
            chipTextColor = isSelected ? Colors.white : regionalTypeColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
          } else {
            Color themeColor = Colors.teal[600]!; // Color de fallback
            chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
            chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
            chipTextColor = isSelected ? Colors.white : Colors.black87;
          }
        } else if (displayName.contains('Primal')) {
          Color themeColor = primalColor;
          chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
          chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        } else if (displayName == 'Base' || displayName == 'forms.base'.tr()) {
          // Usa el color principal del Pokémon para la forma base
          Color themeColor = mainColor;
          chipBackgroundColor = isSelected ? themeColor : Colors.white;
          chipBorderColor = isSelected ? themeColor : Colors.grey.shade300;
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        }
        
        finalChipWidget = Chip(
          avatar: chipAvatar,
          label: Text( displayName, style: TextStyle( color: chipTextColor, fontWeight: FontWeight.bold, shadows: isSelected && chipTextColor == Colors.white ? [ Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5), offset: Offset(1,1)) ] : null, ), ),
          backgroundColor: chipBackgroundColor,
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide( color: chipBorderColor, width: 2, ), ),
          elevation: isSelected ? 4 : 0,
        );
      }
      // --- Fin de Lógica de Estilo ---

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () => _onFormChanged(formName),
          child: finalChipWidget,
        ),
      );
    }).toList();
    
    bool needsScrolling = _varieties.length > 3;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: Row(
            mainAxisAlignment: needsScrolling ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: chips,
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta con ID, Peso y Altura.
  Widget _buildStatsCard(String id, int weight, int height) {
    return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _buildStatColumn('stats.id'.tr(), '#$id'), _buildStatColumn('stats.weight'.tr(), '${weight / 10} kg'), _buildStatColumn('stats.height'.tr(), '${height / 10} m'), ], ), ), );
  }

  /// Widget auxiliar para una sola columna de la tarjeta de estadísticas (ej. "PESO", "8.5 kg").
  Widget _buildStatColumn(String label, String value) {
    return Column( children: [ Text(label.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), ], );
  }

  /// Construye un chip de tipo (ej. "Planta") con su color e icono.
  Widget _buildTypeChip(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Chip( 
      backgroundColor: typeColor, 
      label: Text(
        'types.$type'.tr().toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ), 
      avatar: SvgPicture.network(typeImageUrl, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)), 
    );
  }

  /// Formatea el nombre de la estadística de la API (ej. 'special-attack')
  /// a una clave de traducción (ej. 'stats.sp_atk').
  String _formatStatName(String statName) {
    switch (statName) {
      case 'hp': return 'stats.hp';
      case 'attack': return 'stats.attack';
      case 'defense': return 'stats.defense';
      case 'special-attack': return 'stats.sp_atk';
      case 'special-defense': return 'stats.sp_def';
      case 'speed': return 'stats.speed';
      default: return statName.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  /// Construye una sola fila de barra de estadística (ej. HP: 45 [||||----]).
  Widget _buildStatBar(dynamic stat) {
    final String name = stat['stat']['name'];
    final int value = stat['base_stat'];
    
    // Determina el color de la barra basado en el valor
    Color barColor;
    if (value <= 59) { barColor = Colors.red; }
    else if (value <= 99) { barColor = Colors.yellow.shade700; }
    else if (value <= 159) { barColor = Colors.green; }
    else { barColor = Colors.blue; }
    
    // Normaliza el valor (asumiendo un máximo de ~200 para el UI)
    final double normalizedValue = value > 200 ? 1.0 : (value / 200.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ 
            SizedBox(width: 80, child: Text(_formatStatName(name).tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)), 
            Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), 
          ], ),
          const SizedBox(height: 2),
          ClipRRect( borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: normalizedValue, backgroundColor: barColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(barColor), minHeight: 12), ),
        ],
      ),
    );
  }

  /// Construye un pequeño icono de tipo (para la tabla de defensas).
  Widget _buildTypeIcon(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Container( width: 28, height: 28, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.all(2), child: SvgPicture.network(typeImageUrl, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), placeholderBuilder: (context) => SizedBox.shrink()), );
  }

  /// Construye una celda para la tabla de defensas (icono + multiplicador).
  Widget _buildTypeEffectivenessItem(String type, double multiplier) {
    String multiplierText;
    Color multiplierColor;
    if (multiplier == 4.0) { multiplierText = 'x4'; multiplierColor = Colors.red.shade900; }
    else if (multiplier == 2.0) { multiplierText = 'x2'; multiplierColor = Colors.orange.shade700; }
    else if (multiplier == 0.5) { multiplierText = 'x½'; multiplierColor = Colors.lightGreen.shade600; }
    else if (multiplier == 0.25) { multiplierText = 'x¼'; multiplierColor = Colors.green.shade800; }
    else if (multiplier == 0.0) { multiplierText = 'x0'; multiplierColor = Colors.black87; }
    else { multiplierText = ''; multiplierColor = Colors.transparent; }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [ 
          _buildTypeIcon(type), 
          const SizedBox(height: 4), 
          SizedBox( height: 16, child: Text( multiplierText, style: TextStyle(fontWeight: FontWeight.bold, color: multiplierColor, fontSize: 11), ), ) 
        ],
      ),
    );
  }

  /// Construye la sección de la Cadena Evolutiva completa.
  /// Contiene la lógica para decidir si usar un [SingleChildScrollView]
  /// o simplemente centrar el contenido.
  Widget _buildEvolutionSection() {
    if (_isLoadingEvolution) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator()))
      );
    }
    
    if (_evolutionChainData == null || _evolutionChainData?['chain'] == null) {
      return SizedBox.shrink(); // No mostrar nada si no hay cadena
    }
    
    final chain = _evolutionChainData!['chain'];
    final baseName = chain['species']['name'];
    final List<dynamic> evolutions = chain['evolves_to'] ?? [];
    
    final List<dynamic> filteredEvolutions = _filterEvolutions(evolutions, baseName, _regionSuffixForEvo);
    
    // Construimos el árbol visual recursivamente
    Widget evolutionTree = _buildEvolutionBranch(chain, _regionSuffixForEvo);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        
        // Usamos SIEMPRE el SingleChildScrollView.
        // Es la forma más robusta de manejar todos los casos.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          
          // NOTA: Se omite "physics: BouncingScrollPhysics()" a propósito.
          // De esta forma, si el contenido cabe (ej. 2 etapas),
          // NO se podrá scrollear. Si el contenido se desborda (3+ etapas),
          // SÍ se podrá scrollear.
          
          // Este ConstrainedBox asegura que el área tenga al menos el ancho de la pantalla.
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64), // 32 padding card + 32 padding page
            
            // Este Center se encarga de centrar las cadenas cortas (1 o 2 etapas).
            child: Center(
              child: evolutionTree,
            ),
          ),
        ),
      ),
    );
  }

  /// Filtra la lista de evoluciones para mostrar solo las relevantes
  /// (ej. solo evoluciones de Galar si estamos viendo a Slowpoke de Galar).
  List<dynamic> _filterEvolutions(List<dynamic> evolutions, String baseName, String regionSuffix) {
    if (regionSuffix == '-galar') {
      return evolutions.where((e) {
        String evoName = e['species']['name'];
        List<dynamic> detailsList = e['evolution_details'];
        if (detailsList.isEmpty) return false;
        // Filtro para Slowpoke-Galar (evoluciona con items)
        bool hasGalarItem = detailsList.any((d) {
          String itemName = d['item']?['name'] ?? "";
          return itemName == 'galarica-cuff' || itemName == 'galarica-wreath';
        });
        if (hasGalarItem) return true; 
        if (_galarianEvolutions.contains(evoName)) return true;
        if (_galarianForms.contains(evoName)) {
            // Filtra evoluciones de Kanto (ej. Slowbro-Kanto)
            bool isKantoMethod = detailsList.any((d) {
              return (d['min_level'] != null && d['min_level'] == 37) || 
                     (d['item']?['name'] == 'kings-rock');
            });
            if (isKantoMethod && baseName == 'slowpoke') return false;
            return true;
        }
        return false;
      }).toList();
    }
    if (regionSuffix == '-hisui') {
      // Muestra solo Pokémon de la línea de Hisui
      return evolutions.where((e) => _hisuiLine.contains(e['species']['name'])).toList();
    }
    if (regionSuffix == '-paldea') {
      // Muestra solo Pokémon de la línea de Paldea
      return evolutions.where((e) => _paldeaLine.contains(e['species']['name'])).toList();
    }
    
    // Lógica por defecto (para formas Kanto/Base)
    return evolutions.where((e) {
      String evoName = e['species']['name'];
      // Oculta evoluciones regionales si estamos en la forma base (ej. no mostrar Obstagoon desde Linoone-Kanto)
      if ((_galarianEvolutions.contains(evoName) || 
           _hisuianEvolutions.contains(evoName) || 
           _paldeanEvolutions.contains(evoName)) &&
          _branchReplacements.contains(baseName)) {
        return false; 
      }
      // Oculta evoluciones de Galar si estamos en Slowpoke-Kanto
      if (baseName == 'slowpoke') {
         var details = e['evolution_details'];
         if (details.isNotEmpty) {
           String itemName = details.first['item']?['name'] ?? "";
           if (itemName == 'galarica-cuff' || itemName == 'galarica-wreath') { return false; }
         }
      }
      return true;
    }).toList();
  }

  /// Construye recursivamente el árbol de evolución (un nodo + sus ramas).
  Widget _buildEvolutionBranch(Map<String, dynamic> chainLink, String regionSuffix) {
    if (chainLink.isEmpty) return SizedBox.shrink();
    
    String baseName = chainLink['species']['name'];
    String pokemonName = baseName;
    
    // --- Lógica para determinar el nombre correcto del 'pokemon' ---
    if (pokemonName == 'dudunsparce') {
      pokemonName = 'dudunsparce-two-segment';
    }
    String suffixForThisNode = "";
    if (_galarianEvolutions.contains(baseName) || _hisuianEvolutions.contains(baseName) || _paldeanEvolutions.contains(baseName)) {
      pokemonName = baseName;
      if (baseName == 'dudunsparce') {
        pokemonName = 'dudunsparce-two-segment';
      }
    }
    else if (_alolanForms.contains(baseName) && regionSuffix == "-alola") { suffixForThisNode = "-alola"; }
    else if (_galarianForms.contains(baseName) && regionSuffix == "-galar") { suffixForThisNode = "-galar"; }
    else if (_hisuianForms.contains(baseName) && regionSuffix == "-hisui") { suffixForThisNode = "-hisui"; }
    else if (_paldeanForms.contains(baseName) && regionSuffix == "-paldea") { suffixForThisNode = "-paldea"; }
    
    // Lógica para mostrar formas Alola (ej. Raichu-Alola) desde pre-evos de Kanto
    String currentBaseName = widget.species['name'];
    if (regionSuffix.isEmpty && (currentBaseName == 'pikachu' || currentBaseName == 'exeggcute' || currentBaseName == 'cubone')) {
      if (baseName == 'raichu' || baseName == 'exeggutor' || baseName == 'marowak') { suffixForThisNode = "-alola"; }
    }
    // Lógica para Slowpoke-Galar
    if ((baseName == 'slowbro' || baseName == 'slowking') && (_currentPokemonNameForEvo == 'slowpoke-galar' || regionSuffix == '-galar')) {
      var details = chainLink['evolution_details'];
      if (details.isNotEmpty) {
        bool hasGalarItem = details.any((d) {
          String itemName = d['item']?['name'] ?? "";
          return itemName == 'galarica-cuff' || itemName == 'galarica-wreath';
        });
        if (hasGalarItem) { suffixForThisNode = '-galar'; }
      }
    }
    if (pokemonName == baseName) { pokemonName = "$baseName$suffixForThisNode"; }
    if (pokemonName == 'darmanitan-galar') { pokemonName = 'darmanitan-galar-standard'; }
    // --- Fin de la lógica del nombre ---

    bool isCurrent = _currentPokemonNameForEvo == pokemonName;
    
    // Construye el NODO actual (ej. Spearow)
    Widget currentPokemonWidget = _buildEvolutionNode(pokemonName, isCurrent);
    
    List<dynamic> evolutions = chainLink['evolves_to'] ?? [];
    List<dynamic> filteredEvolutions = _filterEvolutions(evolutions, baseName, regionSuffix);
    
    // Si no hay más evoluciones, devuelve solo el nodo actual
    if (filteredEvolutions.isEmpty) { return currentPokemonWidget; }
    
    // Si hay evoluciones, constrúyelas recursivamente
    List<Widget> evolutionWidgets = []; 
    for (var evoLink in filteredEvolutions) {
      String evolutionDetails = _formatEvolutionDetails( evoLink['evolution_details'], baseName, evoLink['species']['name'], regionSuffix );
      Widget nextPokemonWidget = _buildEvolutionBranch(evoLink, regionSuffix); // Recursión
      evolutionWidgets.add( _buildEvolutionArrowRow(evolutionDetails, nextPokemonWidget) );
    }

    // Añade espacio vertical entre múltiples ramas (ej. Eevee)
    List<Widget> spacedEvolutionWidgets = [];
    for (int i = 0; i < evolutionWidgets.length; i++) {
      spacedEvolutionWidgets.add(evolutionWidgets[i]);
      if (i < evolutionWidgets.length - 1) {
        spacedEvolutionWidgets.add(const SizedBox(height: 32.0));
      }
    }

    // Devuelve el NODO + RAMAS
    return Row(
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [ 
        currentPokemonWidget, 
        const SizedBox(width: 8.0), // Espacio entre nodo y flecha
        Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.center, 
          children: spacedEvolutionWidgets,
        ), 
      ],
    );
  }

  /// Construye una fila de evolución (Flecha con detalles + Siguiente Pokémon).
  Widget _buildEvolutionArrowRow(String evolutionDetails, Widget nextPokemonWidget) {
    return Row(
      children: [
        Container(
          width: 110.0, // Tu ancho personalizado
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_rounded, color: Colors.grey[600]),
              if (evolutionDetails.isNotEmpty)
                Container( 
                  child: Text(
                    evolutionDetails, // Texto ya traducido
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
            ],
          ),
        ),
        nextPokemonWidget,
      ],
    );
  }

  /// Formatea la lista de detalles de evolución en un string legible.
  /// Usa el mapa [_regionalEvolutionOverrides] para casos especiales.
  String _formatEvolutionDetails(List<dynamic> detailsList, String fromPokemonName, String toPokemonName, String regionSuffix) {
    // 1. Revisa los 'overrides' para métodos complejos
    String region = regionSuffix.replaceAll('-', '');
    String complexKey = "$region:$fromPokemonName>$toPokemonName";
    if (_regionalEvolutionOverrides.containsKey(complexKey)) { return _regionalEvolutionOverrides[complexKey]!.tr(); }
    String simpleKey = "$region:$fromPokemonName";
    if (_regionalEvolutionOverrides.containsKey(simpleKey)) { return _regionalEvolutionOverrides[simpleKey]!.tr(); }
    
    // Fallback para evoluciones regionales (ej. Dunsparce -> Dudunsparce-Paldea)
    if (region.isEmpty) {
      if (_paldeanEvolutions.contains(toPokemonName)) {
        String paldeaKey = "paldea:$fromPokemonName";
        if (_regionalEvolutionOverrides.containsKey(paldeaKey)) { return _regionalEvolutionOverrides[paldeaKey]!.tr(); }
      }
      if (_hisuianEvolutions.contains(toPokemonName)) {
        String hisuiKey = "hisui:$fromPokemonName";
        if (_regionalEvolutionOverrides.containsKey(hisuiKey)) { return _regionalEvolutionOverrides[hisuiKey]!.tr(); }
      }
      if (_galarianEvolutions.contains(toPokemonName)) {
        String galarKey = "galar:$fromPokemonName";
        if (_regionalEvolutionOverrides.containsKey(galarKey)) { return _regionalEvolutionOverrides[galarKey]!.tr(); }
      }
    }
    // Casos especiales (Lycanroc, Dudunsparce)
    if (toPokemonName.startsWith('lycanroc') && detailsList.isNotEmpty) {
      var details = detailsList.first;
      String timeOfDay = details['time_of_day'] ?? "";
      String trigger = details['trigger']?['name'] ?? "";
      if (timeOfDay == 'night') return 'evolutions.override_lycanroc_night'.tr();
      if (trigger == 'other') return 'evolutions.override_lycanroc_dusk'.tr();
      return 'evolutions.override_lycanroc_day'.tr();
    }
    if (toPokemonName.startsWith('dudunsparce') && detailsList.isNotEmpty) {
        return 'evolutions.override_paldea_dunsparce'.tr();
    }

    if (detailsList.isEmpty) return "";
    
    // 2. Procesa los métodos de evolución estándar
    dynamic details = detailsList.first;
    if (region.isNotEmpty) {
      final regionalDetail = detailsList.firstWhere( (d) => d['location']?['name'] == region, orElse: () => detailsList.first, );
      details = regionalDetail;
    }
    String trigger = details['trigger']['name'].replaceAll('-', ' ');
    String item = details['item']?['name']?.replaceAll('-', ' ') ?? "";
    String minLevel = details['min_level']?.toString() ?? "";
    String minHappiness = details['min_happiness']?.toString() ?? "";
    String timeOfDay = details['time_of_day'] ?? "";
    String knownMove = details['known_move']?['name']?.replaceAll('-', ' ') ?? "";
    String knownMoveType = details['known_move_type']?['name'] ?? "";
    String location = details['location']?['name']?.replaceAll('-', ' ') ?? "";
    String formattedDetails = "";
    
    // Traduce el método de evolución a un string
    if (minLevel.isNotEmpty) formattedDetails += 'evolutions.lvl'.tr(namedArgs: {'level': minLevel});
    else if (item.isNotEmpty) formattedDetails += 'evolutions.use_item'.tr(namedArgs: {'item': item[0].toUpperCase() + item.substring(1)});
    else if (trigger == "trade") formattedDetails += 'evolutions.trade'.tr();
    else if (minHappiness.isNotEmpty) formattedDetails += 'evolutions.friendship'.tr();
    else if (knownMove.isNotEmpty) formattedDetails += 'evolutions.knows_move'.tr(namedArgs: {'move': knownMove});
    else if (knownMoveType.isNotEmpty) formattedDetails += 'evolutions.knows_move_type'.tr(namedArgs: {'type': knownMoveType});
    else if (location.isNotEmpty) formattedDetails += 'evolutions.in_location'.tr(namedArgs: {'location': location});
    else if (trigger == "other" || trigger == "recoil damage") formattedDetails = 'evolutions.special'.tr();
    else formattedDetails += trigger[0].toUpperCase() + trigger.substring(1);
    
    if (timeOfDay.isNotEmpty && !formattedDetails.contains(timeOfDay)) {
      formattedDetails += "\n($timeOfDay)"; // No traducido, se añade tal cual
    }
    return formattedDetails;
  }

  /// Construye un solo nodo de Pokémon (imagen + nombre) para el árbol de evolución.
  Widget _buildEvolutionNode(String pokemonName, bool isCurrent) {
    Future<Map<String, dynamic>> evolutionNodeFuture;
    
    // Las formas de Lycanroc/Dudunsparce son 'pokemon', no 'pokemon-species' por defecto
    if (pokemonName.startsWith('lycanroc-') || pokemonName.startsWith('dudunsparce-')) {
      evolutionNodeFuture = _apiService.fetchPokemonDetails(pokemonName);
    } else {
      // Usa el método robusto que puede manejar 'pikachu' o 'pikachu-alola'
      evolutionNodeFuture = _apiService.fetchDefaultPokemonDetailsFromSpecies(pokemonName);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: evolutionNodeFuture, 
      builder: (context, snapshot) {
        // --- Manejo de Estados de Carga y Error ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(width: 100, height: 110, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (snapshot.hasError) {
          // Fallback complejo para formas
          if (pokemonName.startsWith('lycanroc-') || pokemonName.startsWith('dudunsparce-')) {
            print("Error cargando _buildEvolutionNode (fetchPokemonDetails): $pokemonName. Error: ${snapshot.error}");
            return Container(width: 100, height: 110, child: Icon(Icons.error_outline, color: Colors.red));
          }
          if(pokemonName.contains('-') && !pokemonName.endsWith('-standard')) {
            String baseName = pokemonName.split('-').first;
            bool isCurrentBase = _currentPokemonNameForEvo.split('-').first == baseName;
            return _buildEvolutionNode(baseName, isCurrentBase);
          }
          if(pokemonName == 'darmanitan-galar-standard') {
            return _buildEvolutionNode('darmanitan-galar', isCurrent);
          }
          print("Error cargando _buildEvolutionNode (fetchDefaultPokemonDetailsFromSpecies): $pokemonName. Error: ${snapshot.error}");
          return Container(width: 100, height: 110, child: Icon(Icons.error_outline, color: Colors.red));
        }

        if (!snapshot.hasData) return SizedBox.shrink();

        // --- Construcción del Nodo ---
        final pokemonData = snapshot.data!;
        final spriteUrl = pokemonData['sprites']?['front_default'] ?? '';
        final types = (pokemonData['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
        final mainColor = types.isNotEmpty ? getTypeColor(types.first) : Colors.grey;

        final String actualPokemonName = pokemonData['name'];
        final bool isCurrentFinal = isCurrent;

        return GestureDetector(
          onTap: () {
            if (isCurrentFinal) return; // No hacer nada si ya está en esta pantalla
            _navigateToPokemon(actualPokemonName);
          },
          child: Container(
            width: 100, // Tu ancho personalizado
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isCurrentFinal ? mainColor.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentFinal ? Border.all(color: mainColor, width: 2) : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                if (spriteUrl.isNotEmpty)
                  Image.network(
                    spriteUrl, 
                    width: 70, // Tu tamaño personalizado
                    height: 70, // Tu tamaño personalizado
                    fit: BoxFit.contain, 
                    errorBuilder: (c, e, s) => Icon(Icons.image_not_supported, size: 70, color: Colors.grey)
                  ),
                SizedBox(height: 4),
                Text(
                  actualPokemonName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), // Tu tamaño de fuente
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}