import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'utils/type_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Pantalla que muestra los detalles de un Pokémon específico.
class PokemonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  const PokemonDetailScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  bool _isLoadingAbilities = true;
  final Map<String, String> _abilityDetails = {};

  @override
  void initState() {
    super.initState();
    // Obtiene las descripciones de las habilidades al iniciar.
    _fetchAbilityDetails();
  }

  /// Obtiene las descripciones de las habilidades en paralelo.
  Future<void> _fetchAbilityDetails() async {
    final abilities = (widget.pokemon['abilities'] as List<dynamic>);
    List<Future<Map<String, String?>>> futures = [];
    for (var abilityInfo in abilities) {
      final abilityUrl = abilityInfo['ability']['url'] as String;
      final abilityName = abilityInfo['ability']['name'] as String;
      futures.add(_fetchSingleAbility(abilityUrl, abilityName));
    }
    try {
      final results = await Future.wait(futures);
      if (mounted) { // Verifica si el widget sigue activo.
        setState(() {
          for (var res in results) {
            _abilityDetails[res['name']!] = res['effect'] ?? 'Description not available.'; 
          }
          _isLoadingAbilities = false;
        });
      }
    } catch (e) {
      print('Error al obtener habilidades: $e'); // Manejo de errores por si no encontro una habilidad
      if (mounted) { setState(() { _isLoadingAbilities = false; }); }
    }
  }

  /// Obtiene la descripción corta de la habilidad
  Future<Map<String, String?>> _fetchSingleAbility(String url, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final effectEntries = (data['effect_entries'] as List<dynamic>);
        final entry = effectEntries.firstWhere((e) => e['language']['name'] == 'en', orElse: () => null);
        final description = entry != null ? entry['short_effect'] as String : null;
        return {'name': name, 'effect': description};
      }
    } catch (e) {
      print('Error al obtener $name: $e'); 
    }
    return {'name': name, 'effect': 'Error loading.'}; 
  }

  @override
  Widget build(BuildContext context) {
    // Extrae todos los datos necesarios del Pokémon.
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
      appBar: AppBar(
        title: Text(name[0].toUpperCase() + name.substring(1)),
        backgroundColor: mainColor,
      ),
      // Usa un Container con gradiente para el fondo.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.10)],
          ),
        ),
        // Permite el scroll si el contenido es largo.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen principal con animación Hero.
              Hero(
                tag: 'pokemon-$id',
                child: Image.network(imageUrl, width: 250, height: 250, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.error, size: 200, color: Colors.red)),
              ),
              const SizedBox(height: 16),
              // Nombre.
              Text(name.toUpperCase(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              // Tipos.
              Wrap(alignment: WrapAlignment.center, spacing: 8.0, runSpacing: 4.0, children: types.map((type) => _buildTypeChip(type)).toList()),
              const SizedBox(height: 24),
              // Tarjeta de ID, Peso, Altura.
              _buildStatsCard(id, weight, height),
              const SizedBox(height: 24),
              // Sección de Estadísticas Base.
              Text('Base Stats', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(children: stats.map((stat) => _buildStatBar(stat)).toList()),
                ),
              ),
              const SizedBox(height: 24),
              // Sección de Habilidades.
              Text('Abilities', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Muestra carga o la lista de habilidades.
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

  /// Construye la tarjeta con ID, Peso y Altura.
  Widget _buildStatsCard(String id, int weight, int height) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Construye una columna para la tarjeta de stats.
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  /// Construye un Chip para mostrar un tipo (con ícono).
  Widget _buildTypeChip(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Chip(
      backgroundColor: typeColor,
      label: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      avatar: SvgPicture.network(typeImageUrl, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
    );
  }

  /// Estadisticas de los pokemon
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

  /// Construye una barra de progreso para una estadística base.
  Widget _buildStatBar(dynamic stat) {
    final String name = stat['stat']['name'];
    final int value = stat['base_stat'];
    
    // Determina el color según el valor bajo o alto de la estadistica.
    Color barColor;
    if (value <= 59) { barColor = Colors.red; }
    else if (value <= 99) { barColor = Colors.yellow.shade700; }
    else if (value <= 159) { barColor = Colors.green; }
    else { barColor = Colors.blue; }

    // Valor predeterminado de la barra de la estadistica.
    final double normalizedValue = value > 200 ? 1.0 : (value / 200.0);
    // Ajustes de tamaño de la barra
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 80, 
                child: Text(_formatStatName(name), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
              ),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 4),
          // Barra de progreso.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: normalizedValue,
              backgroundColor: barColor.withOpacity(0.2), 
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}