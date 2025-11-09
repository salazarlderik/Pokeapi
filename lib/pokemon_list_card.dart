import 'package:flutter/material.dart';
import 'api_service.dart';
import 'pokemon_detail_screen.dart';
import 'utils/type_colors.dart';

class PokemonListCard extends StatelessWidget {
  final Map<String, dynamic> pokemonSpecies;
  static final ApiService _apiService = ApiService();

  const PokemonListCard({Key? key, required this.pokemonSpecies}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ... (El FutureBuilder no cambia) ...
    final String speciesNameFromEntry = pokemonSpecies['name'];

    final Future<Map<String, dynamic>> cardDataFuture = () async {
      final speciesData = await _apiService.fetchPokemonSpecies(speciesNameFromEntry);
      final varieties = speciesData['varieties'] as List<dynamic>;
      if (varieties.isEmpty) {
        throw Exception('No varieties found for $speciesNameFromEntry');
      }
      final defaultVariety = varieties.firstWhere(
        (v) => v['is_default'] == true,
        orElse: () => varieties.first,
      );
      final String defaultPokemonName = defaultVariety['pokemon']['name'];
      final pokemonDetails = await _apiService.fetchPokemonDetails(defaultPokemonName);
      return {
        'species': speciesData,
        'details': pokemonDetails,
      };
    }();

    return FutureBuilder<Map<String, dynamic>>(
      future: cardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Error cargando datos encadenados para $speciesNameFromEntry: ${snapshot.error}');
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
          );
        }

        final pokemonDetails = snapshot.data?['details'] as Map<String, dynamic>?;
        final pokemonSpeciesData = snapshot.data?['species'] as Map<String, dynamic>?;

        if (pokemonDetails == null || pokemonSpeciesData == null) {
          return Card(child: Center(child: Text('No data')));
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(
                  pokemon: pokemonDetails,
                  species: pokemonSpeciesData,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildPokemonCardContent(context, pokemonDetails, pokemonSpeciesData),
        );
      },
    );
  }

  /// Construye el contenido visual de la tarjeta (Con Piedra Activadora Y Logo Gmax)
  Widget _buildPokemonCardContent(
    BuildContext context,
    Map<String, dynamic> pokemon,
    Map<String, dynamic> species,
  ) {
    final name = species['name'] as String; 
    
    final sprites = pokemon['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork = otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final String imageUrl = officialArtwork?['front_default'] as String? 
                            ?? sprites['front_default'] as String? 
                            ?? '';

    final id = species['id'] as int;
    final types = (pokemon['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final cardColor = getTypeColor(types.first).withOpacity(0.15);

    // Detectar si el Pokémon tiene alguna forma Mega
    bool hasMegaEvolution = false;
    // Detectar si el Pokémon tiene forma Gmax
    bool hasGmaxEvolution = false;

    if (species.containsKey('varieties')) {
      final varieties = species['varieties'] as List<dynamic>;
      hasMegaEvolution = varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
      hasGmaxEvolution = varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax'));
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Contenido Principal (Texto e Imagen)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'pokemon-$id',
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: imageUrl.isEmpty
                        ? Icon(Icons.image_not_supported, size: 60, color: Colors.grey)
                        : Image.network(
                            imageUrl, 
                            fit: BoxFit.contain, 
                            errorBuilder: (c, e, s) => Icon(Icons.error_outline, color: Colors.red), 
                            loadingBuilder: (c, ch, p) => p == null ? ch : Center(child: CircularProgressIndicator())
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('#${id.toString().padLeft(3, '0')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.4))),
                    SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(name[0].toUpperCase() + name.substring(1), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: types.map((type) => _buildTypeChip(type, isSmall: true)).toList()),
                    ),
                    SizedBox(height: 4), 
                  ],
                ),
              ),
            ],
          ),

          // Medallón de Piedra Activadora (Esquina superior DERECHA)
          if (hasMegaEvolution)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 16, 
                backgroundColor: Colors.black.withOpacity(0.3), 
                child: Padding(
                  padding: const EdgeInsets.all(3.0), 
                  child: Image.asset(
                    'assets/images/piedra_activadora.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // ==================================================
          // 👇 NUEVO: Medallón de Gmax (Esquina superior IZQUIERDA)
          // ==================================================
          if (hasGmaxEvolution)
            Positioned(
              top: 8,
              left: 8,
              child: CircleAvatar(
                radius: 16, 
                backgroundColor: Colors.red.withOpacity(0.4), // Fondo rojo Gmax
                child: Padding(
                  padding: const EdgeInsets.all(3.0), 
                  child: Image.asset(
                    'assets/images/gmax_logo.png', // Asegúrate de tener esta imagen
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          // ==================================================
          // 👆 FIN DEL CAMBIO
          // ==================================================
        ],
      ),
    );
  }

  /// Construye el chip de tipo.
  Widget _buildTypeChip(String type, {bool isSmall = false}) {
    // ... (Esta función no cambia) ...
    final typeColor = getTypeColor(type);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Chip(
        backgroundColor: typeColor,
        labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8.0 : 12.0),
        padding: EdgeInsets.all(isSmall ? 0 : 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          type.toUpperCase(), 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: isSmall ? 10 : 12,
            shadows: [ 
              Shadow(
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1, 1),
              ),
            ]
          )
        ),
      ),
    );
  }
}