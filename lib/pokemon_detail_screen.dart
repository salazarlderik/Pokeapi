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
  final Map<String, String> _abilityDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchAbilityDetails();
  }

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
      if (mounted) {
        setState(() {
          _isLoadingAbilities = false;
        });
      }
    }
  }

  Future<Map<String, String?>> _fetchSingleAbility(String url, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final effectEntries = (data['effect_entries'] as List<dynamic>);
        final entry = effectEntries.firstWhere(
          (e) => e['language']['name'] == 'en',
          orElse: () => null,
        );
        final description = entry != null ? entry['short_effect'] as String : null;
        return {'name': name, 'effect': description};
      }
    } catch (e) {
      print('Error fetching $name: $e');
    }
    return {'name': name, 'effect': 'Error loading.'};
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.pokemon['name'];
    final String id = widget.pokemon['id'].toString();
    final String imageUrl = widget.pokemon['sprites']['other']['official-artwork']
            ['front_default'] ??
        widget.pokemon['sprites']['front_default'];
    final types = (widget.pokemon['types'] as List<dynamic>)
        .map<String>((type) => type['type']['name'] as String)
        .toList();
    final abilityNames = (widget.pokemon['abilities'] as List<dynamic>)
        .map<String>((ability) => ability['ability']['name'] as String)
        .toList();
    final int height = widget.pokemon['height'];
    final int weight = widget.pokemon['weight'];
    final stats = (widget.pokemon['stats'] as List<dynamic>);

    final mainColor = getTypeColor(types.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(name[0].toUpperCase() + name.substring(1)),
        backgroundColor: mainColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              mainColor.withOpacity(0.25),
              mainColor.withOpacity(0.10),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: 'pokemon-$id',
                child: Image.network(
                  imageUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error, size: 200, color: Colors.red);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0,
                runSpacing: 4.0,
                children: types.map((type) => _buildTypeChip(type)).toList(),
              ),
              const SizedBox(height: 24),
              _buildStatsCard(id, weight, height),

              const SizedBox(height: 24),
              Text(
                'Base Stats',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: stats.map((stat) => _buildStatBar(stat)).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Abilities',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _isLoadingAbilities
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: abilityNames.length,
                      itemBuilder: (context, index) {
                        final abilityName = abilityNames[index];
                        final description =
                            _abilityDetails[abilityName] ?? 'Loading...';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              abilityName[0].toUpperCase() +
                                  abilityName.substring(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            subtitle: Text(
                              description.replaceAll('\n', ' '),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl =
        'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Chip(
      backgroundColor: typeColor,
      label: Text(
        type.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      avatar: SvgPicture.network(
        typeImageUrl,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  /// Formatea el nombre de la estadística para mostrarlo en inglés
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

  // --- INICIO DEL CAMBIO ---
  // Se eliminó _getStatColor ya que el color ahora depende del valor

  /// Construye una sola barra de estadística (Nombre, Valor y Barra con color dinámico)
  Widget _buildStatBar(dynamic stat) {
    final String name = stat['stat']['name'];
    final int value = stat['base_stat'];
    
    // 1. Determinar el color de la barra según el valor
    Color barColor;
    if (value <= 59) {
      barColor = Colors.red;
    } else if (value <= 99) {
      barColor = Colors.yellow.shade700; // Un amarillo más visible
    } else if (value <= 159) {
      barColor = Colors.green;
    } else { // 160 o más
      barColor = Colors.blue;
    }

    // 2. Normalizar el valor (máximo visual 200, como antes)
    final double normalizedValue = value > 200 ? 1.0 : (value / 200.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3. Hacer el nombre del stat un poco más estrecho para dar espacio
              SizedBox(
                width: 80, // Ancho fijo para el nombre del stat
                child: Text(
                  _formatStatName(name),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis, // Por si acaso
                ),
              ),
              // 4. Mostrar el valor numérico
              Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: normalizedValue,
              // 5. Usar el color determinado para el fondo y la barra
              backgroundColor: barColor.withOpacity(0.2), 
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
  // --- FIN DEL CAMBIO ---
}