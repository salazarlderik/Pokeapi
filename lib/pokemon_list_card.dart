import 'package:flutter/material.dart';
import 'api_service.dart';
import 'pokemon_detail_screen.dart';
import 'utils/type_colors.dart';

/// Un widget de tarjeta individual que obtiene sus propios datos (Lazy Loading).
class PokemonListCard extends StatelessWidget {
  final Map<String, dynamic> pokemonSpecies;
  static final ApiService _apiService = ApiService();

  const PokemonListCard({Key? key, required this.pokemonSpecies}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Este es el nombre de la ESPECIE, ej: 'wishiwashi' o 'toxtricity-amped'
    final String speciesNameFromEntry = pokemonSpecies['name'];

    // Este Future ahora encadena las llamadas:
    // 1. Llama a fetchPokemonSpecies() para obtener la info de la especie.
    // 2. De esa info, saca el nombre del Pokémon "default".
    // 3. Llama a fetchPokemonDetails() con ese nombre "default".
    final Future<Map<String, dynamic>> cardDataFuture = () async {
      // 1. Obtener datos de la ESPECIE
      // (ApiService.fetchPokemonSpecies ya usa .split('-').first,
      // así que 'toxtricity-amped' se vuelve 'toxtricity', lo cual es correcto)
      final speciesData = await _apiService.fetchPokemonSpecies(speciesNameFromEntry);

      // 2. Encontrar el nombre del Pokémon por defecto
      final varieties = speciesData['varieties'] as List<dynamic>;
      if (varieties.isEmpty) {
        throw Exception('No varieties found for $speciesNameFromEntry');
      }

      // Buscamos la variedad que es "default: true"
      // Si no la encontramos (ej. Unown), usamos la primera de la lista como fallback.
      final defaultVariety = varieties.firstWhere(
        (v) => v['is_default'] == true,
        orElse: () => varieties.first,
      );
      
      // Este es el nombre REAL del Pokémon para el endpoint /pokemon/
      // ej: 'wishiwashi-solo', 'lycanroc-midday', 'minior-red-meteor'
      final String defaultPokemonName = defaultVariety['pokemon']['name'];

      // 3. Obtener los detalles (sprites, tipos) de ESE Pokémon
      final pokemonDetails = await _apiService.fetchPokemonDetails(defaultPokemonName);

      // 4. Devolver ambos mapas
      return {
        'species': speciesData,
        'details': pokemonDetails,
      };
    }(); // Invocamos la función anónima para que el Future se ejecute

    // El FutureBuilder ahora espera un Map<String, dynamic>
    return FutureBuilder<Map<String, dynamic>>(
      future: cardDataFuture,
      builder: (context, snapshot) {
        
        // --- Caso 1: Cargando ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // --- Caso 2: Error ---
        if (snapshot.hasError) {
          // Ahora usamos speciesNameFromEntry para el log
          print('Error cargando datos encadenados para $speciesNameFromEntry: ${snapshot.error}');
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
          );
        }

        // --- Caso 3: Éxito ---
        // Extraemos los datos del Map
        final pokemonDetails = snapshot.data?['details'] as Map<String, dynamic>?;
        final pokemonSpeciesData = snapshot.data?['species'] as Map<String, dynamic>?;

        if (pokemonDetails == null || pokemonSpeciesData == null) {
          return Card(child: Center(child: Text('No data')));
        }

        // ¡Ahora tenemos ambos!
        return InkWell(
          onTap: () {
            // Pasamos AMBOS datos a la pantalla de detalle
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(
                  pokemon: pokemonDetails,
                  species: pokemonSpeciesData, // Pasa los datos de la especie
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          // Pasamos ambos mapas de datos al widget de contenido.
          child: _buildPokemonCardContent(context, pokemonDetails, pokemonSpeciesData),
        );
      },
    );
  }

  /// Construye el contenido visual de la tarjeta.
  Widget _buildPokemonCardContent(
    BuildContext context,
    Map<String, dynamic> pokemon,
    Map<String, dynamic> species, // Recibe los datos de la especie
  ) {
    // NOTA: 'pokemon' ahora contiene los datos de la forma default
    // (ej. 'lycanroc-midday') mientras que 'species' contiene los
    // datos de la especie (ej. 'lycanroc')

    // Usamos el nombre de la ESPECIE para la tarjeta, no el de la forma
    // (ej. 'Lycanroc' en lugar de 'Lycanroc-midday')
    final name = species['name'] as String; 
    
    // --- INICIO DE LA CORRECCIÓN (IMAGEN SEGURA) ---
    final sprites = pokemon['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork = otherSprites?['official-artwork'] as Map<String, dynamic>?;
    
    // Busca el artwork oficial, si no, el sprite frontal, si no, una cadena vacía
    final String imageUrl = officialArtwork?['front_default'] as String? 
                            ?? sprites['front_default'] as String? 
                            ?? ''; // Fallback final
    // --- FIN DE LA CORRECCIÓN ---

    // Usamos el ID de la ESPECIE para el Hero y el texto
    final id = species['id'] as int;
    final types = (pokemon['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final cardColor = getTypeColor(types.first).withOpacity(0.15);

    // Lógica de Megaevolución (esto ya estaba bien)
    bool hasMega = false;
    if (species.containsKey('varieties')) {
      final varieties = species['varieties'] as List<dynamic>;
      hasMega = varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Logo Mega (si aplica)
          if (hasMega)
            Positioned(
              top: 8,
              right: 8,
              child: Opacity(
                opacity: 0.2, 
                child: Image.asset(
                  'assets/images/mega_logo.png', // ¡Asegúrate de tener esta imagen!
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
                ),
              ),
            ),
          
          // Contenido Principal
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  // Usamos el ID de la especie (ej. 745)
                  tag: 'pokemon-$id', 
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: imageUrl.isEmpty // Si la URL está vacía, muestra placeholder
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
                    // Usamos el ID de la especie (ej. #745)
                    Text('#$id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.4))),
                    SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      // Usamos el nombre de la especie (ej. Lycanroc)
                      child: Text(name[0].toUpperCase() + name.substring(1), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: types.map((type) => _buildTypeChip(type, isSmall: true)).toList()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el chip de tipo.
  Widget _buildTypeChip(String type, {bool isSmall = false}) {
    final typeColor = getTypeColor(type);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Chip(
        backgroundColor: typeColor,
        labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8.0 : 12.0),
        padding: EdgeInsets.all(isSmall ? 0 : 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(type.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12)),
      ),
    );
  }
}