import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'utils/type_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
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
  final ApiService _apiService = ApiService();

  bool _isLoadingAbilities = true;
  bool _isLoadingTypeDefenses = true;
  bool _isChangingForm = false;

  Map<String, String> _abilityDetails = {};
  Map<String, double> _typeEffectiveness = {};
  List<dynamic> _varieties = [];
  
  late Map<String, dynamic> _currentPokemonData;
  late String _currentVarietyName;

  final List<String> _allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice', 
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug', 
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  @override
  void initState() {
    super.initState();
    _currentPokemonData = widget.pokemon;
    _varieties = widget.species['varieties'] ?? [];
    _currentVarietyName = _currentPokemonData['name'];
    _loadAllDataForCurrentForm();
  }
  
  Future<void> _loadAllDataForCurrentForm() async {
    setState(() {
      _isLoadingAbilities = true;
      _isLoadingTypeDefenses = true;
    });
    
    await Future.wait([
      _fetchAbilityDetails(_currentPokemonData),
      _fetchTypeEffectiveness(_currentPokemonData),
    ]);
  }

  Future<void> _fetchAbilityDetails(Map<String, dynamic> pokemonData) async {
    final abilities = (pokemonData['abilities'] as List<dynamic>);
    Map<String, String> newAbilityDetails = {};
    List<Future<Map<String, String?>>> futures = [];
    
    for (var abilityInfo in abilities) {
      final abilityUrl = abilityInfo['ability']['url'] as String;
      final abilityName = abilityInfo['ability']['name'] as String;
      futures.add(_fetchSingleAbility(abilityUrl, abilityName));
    }
    try {
      final results = await Future.wait(futures);
      for (var res in results) {
        newAbilityDetails[res['name']!] = res['effect'] ?? 'Description not available.';
      }
    } catch (e) {
      print('Error fetching abilities: $e');
    }
    
    if (mounted) {
      setState(() {
        _abilityDetails = newAbilityDetails;
        _isLoadingAbilities = false;
      });
    }
  }

  Future<Map<String, String?>> _fetchSingleAbility(String url, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entry = (data['effect_entries'] as List<dynamic>).firstWhere((e) => e['language']['name'] == 'en', orElse: () => null);
        return {'name': name, 'effect': entry != null ? entry['short_effect'] : null};
      }
    } catch (e) { print('Error fetching $name: $e'); }
    return {'name': name, 'effect': 'Error loading.'};
  }

  Future<void> _fetchTypeEffectiveness(Map<String, dynamic> pokemonData) async {
    if (!mounted) return;
    
    Map<String, double> effectivenessMap = { for (var type in _allTypes) type: 1.0 };
    final types = (pokemonData['types'] as List<dynamic>).map<String>((typeInfo) => typeInfo['type']['name'] as String).toList();
    List<Future<http.Response>> typeFutures = [];
    
    for (var typeName in types) {
      typeFutures.add(http.get(Uri.parse('https://pokeapi.co/api/v2/type/$typeName')));
    }
    try {
      final typeResponses = await Future.wait(typeFutures);
      for (var response in typeResponses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['damage_relations'];
          for (var type in data['double_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 2.0; }
          for (var type in data['half_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.5; }
          for (var type in data['no_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.0; }
        }
      }
      if (mounted) {
        setState(() {
          _typeEffectiveness = effectivenessMap;
          _isLoadingTypeDefenses = false;
        });
      }
    } catch (e) {
      print('Error fetching type defenses: $e');
      if (mounted) { setState(() { _isLoadingTypeDefenses = false; }); }
    }
  }

  Future<void> _onFormChanged(String? newFormName) async {
    if (newFormName == null || newFormName == _currentVarietyName) return;

    setState(() { _isChangingForm = true; });

    try {
      final newPokemonData = await _apiService.fetchPokemonDetails(newFormName);
      
      if (mounted) {
        setState(() {
          _currentPokemonData = newPokemonData;
          _currentVarietyName = newFormName;
        });
        await _loadAllDataForCurrentForm();
      }
    } catch (e) {
      print('Error changing form: $e');
    } finally {
      if (mounted) {
        setState(() { _isChangingForm = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String heroId = widget.species['id'].toString();
    final String name = _currentPokemonData['name'];
    
    final sprites = _currentPokemonData['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork = otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final String imageUrl = officialArtwork?['front_default'] as String? 
                            ?? sprites['front_default'] as String? 
                            ?? '';

    final types = (_currentPokemonData['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final abilityNames = (_currentPokemonData['abilities'] as List<dynamic>).map<String>((ability) => ability['ability']['name'] as String).toList();
    final int height = _currentPokemonData['height'];
    final int weight = _currentPokemonData['weight'];
    final stats = (_currentPokemonData['stats'] as List<dynamic>);
    
    final mainColor = getTypeColor(types.first);

    return Scaffold(
      appBar: AppBar(title: Text(name[0].toUpperCase() + name.substring(1)), backgroundColor: mainColor),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.10)])),
        child: _isChangingForm
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormSelector(), 
                    Hero(
                      tag: 'pokemon-$heroId', 
                      child: imageUrl.isEmpty
                          ? Icon(Icons.image_not_supported, size: 200, color: Colors.grey)
                          : Image.network(
                              imageUrl, 
                              width: 250, height: 250, fit: BoxFit.contain, 
                              errorBuilder: (c, e, s) => Icon(Icons.error, size: 200, color: Colors.red)
                            )
                    ),
                    const SizedBox(height: 16),
                    Text(name.toUpperCase(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Wrap(alignment: WrapAlignment.center, spacing: 8.0, runSpacing: 4.0, children: types.map((type) => _buildTypeChip(type)).toList()),
                    const SizedBox(height: 24),
                    _buildStatsCard(heroId, weight, height), 
                    
                    const SizedBox(height: 24),
                    Text('Base Stats', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: stats.map((stat) => _buildStatBar(stat)).toList()))),
                    
                    const SizedBox(height: 24),
                    Text('Type Defenses', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // ===========================================
                    // 👇 AQUÍ EMPIEZA EL CAMBIO (Table por GridView)
                    // ===========================================
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias, // Para que los bordes de la tabla se corten
                      child: _isLoadingTypeDefenses
                          ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                          : Table(
                              // Esta es la clave para las "líneas delgadas"
                              border: TableBorder.all(
                                color: Colors.grey.shade300, // Color del borde
                                width: 1.0, // Grosor del borde
                              ),
                              children: [
                                // Fila 1 (los primeros 9 tipos)
                                _buildTypeRow(_allTypes.sublist(0, 9)),
                                // Fila 2 (los últimos 9 tipos)
                                _buildTypeRow(_allTypes.sublist(9, 18)),
                              ],
                            ),
                    ),
                    // ===========================================
                    // 👆 AQUÍ TERMINA EL CAMBIO
                    // ===========================================
                    
                    const SizedBox(height: 24),
                    Text('Abilities', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _isLoadingAbilities
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            itemCount: abilityNames.length,
                            itemBuilder: (context, index) {
                              final abilityName = abilityNames[index];
                              final description = _abilityDetails[abilityName] ?? 'Loading...';
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

  // --- WIDGETS AUXILIARES (HELPERS) ---

  // ===========================================
  // 👇 NUEVA FUNCIÓN AUXILIAR PARA LA TABLA
  // ===========================================
  /// Construye una fila (TableRow) para la tabla de defensas de tipo.
  TableRow _buildTypeRow(List<String> types) {
    return TableRow(
      children: types.map((type) {
        final double multiplier = _typeEffectiveness[type] ?? 1.0;
        // Reutilizamos el widget que ya teníamos para construir la celda
        return _buildTypeEffectivenessItem(type, multiplier);
      }).toList(),
    );
  }

  Widget _buildFormSelector() {
    if (_varieties.length <= 1) { return SizedBox.shrink(); }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: DropdownButtonFormField<String>(
          value: _currentVarietyName,
          isExpanded: true,
          decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.compare_arrows_rounded, color: Colors.grey[700]), labelText: 'Form'),
          onChanged: (String? newFormName) { _onFormChanged(newFormName); },
          items: _varieties.map<DropdownMenuItem<String>>((variety) {
            final String formName = variety['pokemon']['name'];
            final String formattedName = formName.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
            return DropdownMenuItem<String>(value: formName, child: Text(formattedName, overflow: TextOverflow.ellipsis));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String id, int weight, int height) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn('ID', '#$id'),
            _buildStatColumn('Weight', '${weight / 10} kg'), 
            _buildStatColumn('Height', '${height / 10} m'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Chip(
      backgroundColor: typeColor,
      label: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      avatar: SvgPicture.network(typeImageUrl, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
    );
  }

  /// Formatea el nombre de la estadística a un formato legible en inglés
  String _formatStatName(String statName) {
    switch (statName) {
      case 'hp': return 'HP';
      case 'attack': return 'Attack';
      case 'defense': return 'Defense';
      case 'special-attack': return 'Sp. Atk';
      case 'special-defense': return 'Sp. Def';
      case 'speed': return 'Speed';
      default: return statName.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  /// Construye una barra de progreso para una estadística base
  Widget _buildStatBar(dynamic stat) {
    final String name = stat['stat']['name'];
    final int value = stat['base_stat'];
    Color barColor;
    if (value <= 59) { barColor = Colors.red; }
    else if (value <= 99) { barColor = Colors.yellow.shade700; }
    else if (value <= 159) { barColor = Colors.green; }
    else { barColor = Colors.blue; }
    final double normalizedValue = value > 200 ? 1.0 : (value / 200.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 80, child: Text(_formatStatName(name), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: normalizedValue, backgroundColor: barColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(barColor), minHeight: 12),
          ),
        ],
      ),
    );
  }

  /// Construye un ícono pequeño para la tabla de tipos
  Widget _buildTypeIcon(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Container(
      width: 28, 
      height: 28, 
      decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.all(2), 
      child: SvgPicture.network(typeImageUrl, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), placeholderBuilder: (context) => SizedBox.shrink()),
    );
  }

  /// Construye un item para la grilla de defensas de tipo
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
      // ===========================================
      // 👇 AJUSTE DE PADDING PARA LA TABLA
      // ===========================================
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Ajustado para dar espacio
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypeIcon(type),
          const SizedBox(height: 4), // Ajustado para dar espacio
          SizedBox(
            height: 16, 
            child: Text(
              multiplierText, 
              style: TextStyle(fontWeight: FontWeight.bold, color: multiplierColor, fontSize: 11),
            ),
          )
        ],
      ),
    );
  }
}