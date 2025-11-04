import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'utils/type_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  const PokemonDetailScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  bool _isLoadingAbilities = true;
  bool _isLoadingTypeDefenses = true;
  
  Map<String, String> _abilityDetails = {};
  Map<String, double> _typeEffectiveness = {};

  /// Lista fija de todos los tipos en orden
  final List<String> _allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice', 
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug', 
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAbilityDetails();
    _fetchTypeEffectiveness();
  }

  /// Obtiene las descripciones de las habilidades
  Future<void> _fetchAbilityDetails() async {
    // ... (Esta función no cambia) ...
    final abilities = (widget.pokemon['abilities'] as List<dynamic>);
    List<Future<Map<String, String?>>> futures = [];
    for (var abilityInfo in abilities) {
      final abilityUrl = abilityInfo['ability']['url'] as String;
      final abilityName = abilityInfo['ability']['name'] as String;
      futures.add(_fetchSingleAbility(abilityUrl, abilityName));
    }
    try {
      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          for (var res in results) {
            _abilityDetails[res['name']!] = res['effect'] ?? 'Description not available.';
          }
          _isLoadingAbilities = false;
        });
      }
    } catch (e) {
      print('Error fetching abilities: $e');
      if (mounted) { setState(() { _isLoadingAbilities = false; }); }
    }
  }

  /// Obtiene la descripción de una habilidad
  Future<Map<String, String?>> _fetchSingleAbility(String url, String name) async {
    // ... (Esta función no cambia) ...
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

  /// Obtiene y calcula las debilidades y resistencias del Pokémon
  Future<void> _fetchTypeEffectiveness() async {
    // ... (Esta función no cambia) ...
    if (!mounted) return;
    setState(() { _isLoadingTypeDefenses = true; });

    Map<String, double> effectivenessMap = {
      for (var type in _allTypes) type: 1.0
    };
    final types = (widget.pokemon['types'] as List<dynamic>)
        .map<String>((typeInfo) => typeInfo['type']['name'] as String)
        .toList();
    List<Future<http.Response>> typeFutures = [];
    for (var typeName in types) {
      typeFutures.add(http.get(Uri.parse('https://pokeapi.co/api/v2/type/$typeName')));
    }
    try {
      final typeResponses = await Future.wait(typeFutures);
      for (var response in typeResponses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['damage_relations'];
          for (var type in data['double_damage_from']) {
            effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 2.0;
          }
          for (var type in data['half_damage_from']) {
            effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.5;
          }
          for (var type in data['no_damage_from']) {
            effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.0;
          }
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


  @override
  Widget build(BuildContext context) {
    // ... (Extracción de datos no cambia) ...
    final String name = widget.pokemon['name'];
    final String id = widget.pokemon['id'].toString();
    final String imageUrl = widget.pokemon['sprites']['other']['official-artwork']['front_default'] ?? widget.pokemon['sprites']['front_default'];
    final types = (widget.pokemon['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final abilityNames = (widget.pokemon['abilities'] as List<dynamic>).map<String>((ability) => ability['ability']['name'] as String).toList();
    final int height = widget.pokemon['height'];
    final int weight = widget.pokemon['weight'];
    final stats = (widget.pokemon['stats'] as List<dynamic>);
    final mainColor = getTypeColor(types.first);

    return Scaffold(
      appBar: AppBar(title: Text(name[0].toUpperCase() + name.substring(1)), backgroundColor: mainColor),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.10)])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Hero, Nombre, Tipos, StatsCard, Base Stats no cambian) ...
              Hero(tag: 'pokemon-$id', child: Image.network(imageUrl, width: 250, height: 250, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.error, size: 200, color: Colors.red))),
              const SizedBox(height: 16),
              Text(name.toUpperCase(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 8.0, runSpacing: 4.0, children: types.map((type) => _buildTypeChip(type)).toList()),
              const SizedBox(height: 24),
              _buildStatsCard(id, weight, height),
              const SizedBox(height: 24),
              Text('Base Stats', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: stats.map((stat) => _buildStatBar(stat)).toList()))),
              
              // --- SECCIÓN DE DEFENSAS DE TIPO (MODIFICADA) ---
              const SizedBox(height: 24),
              Text(
                'Type Defenses',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoadingTypeDefenses
                      ? Center(child: CircularProgressIndicator())
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.0, // Espacio horizontal
                          runSpacing: 8.0, // Espacio vertical
                          // --- INICIO DEL CAMBIO ---
                          // Itera sobre la lista fija _allTypes para mostrar los 18
                          children: _allTypes.map((type) {
                            // Busca el multiplicador; si no existe (error raro), asume 1.0
                            final double multiplier = _typeEffectiveness[type] ?? 1.0;
                            return _buildTypeEffectivenessItem(type, multiplier);
                          }).toList(),
                          // --- FIN DEL CAMBIO ---
                        ),
                ),
              ),
              // --- FIN SECCIÓN DE DEFENSAS ---

              const SizedBox(height: 24),
              Text('Abilities', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isLoadingAbilities
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      // ... (Sección de Habilidades no cambia) ...
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: abilityNames.length,
                      itemBuilder: (context, index) {
                        final abilityName = abilityNames[index];
                        final description = _abilityDetails[abilityName] ?? 'Loading...';
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

  // ... (_buildStatsCard, _buildStatColumn, _buildTypeChip, _formatStatName, _buildStatBar no cambian) ...
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
          const SizedBox(height: 4),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: SvgPicture.network(
        typeImageUrl,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        placeholderBuilder: (context) => SizedBox.shrink(),
      ),
    );
  }

  /// Construye un item para la grilla de defensas de tipo (Ícono + Multiplicador)
  Widget _buildTypeEffectivenessItem(String type, double multiplier) {
    String multiplierText;
    Color multiplierColor;

    if (multiplier == 4.0) {
      multiplierText = 'x4';
      multiplierColor = Colors.red.shade700;
    } else if (multiplier == 2.0) {
      multiplierText = 'x2';
      multiplierColor = Colors.red;
    } else if (multiplier == 0.5) {
      multiplierText = 'x½';
      multiplierColor = Colors.green.shade700;
    } else if (multiplier == 0.25) {
      multiplierText = 'x¼';
      multiplierColor = Colors.green.shade900;
    } else if (multiplier == 0.0) {
      multiplierText = 'x0';
      multiplierColor = Colors.black87;
    } else {
      // --- INICIO DEL CAMBIO ---
      // Caso Neutro (x1)
      multiplierText = ''; // Texto vacío
      multiplierColor = Colors.transparent; // Color invisible
      // --- FIN DEL CAMBIO ---
    }

    return SizedBox(
      width: 50,
      child: Column(
        children: [
          _buildTypeIcon(type), // Siempre muestra el ícono
          const SizedBox(height: 4),
          // --- INICIO DEL CAMBIO ---
          // Usamos un SizedBox para reservar el espacio vertical,
          // asegurando que todos los íconos se alineen perfectamente.
          SizedBox(
            height: 18, // Altura aproximada del texto
            child: Text(
              multiplierText,
              style: TextStyle(fontWeight: FontWeight.bold, color: multiplierColor, fontSize: 14),
            ),
          )
          // --- FIN DEL CAMBIO ---
        ],
      ),
    );
  }
}