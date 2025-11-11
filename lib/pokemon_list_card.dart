import 'package:flutter/material.dart';
import 'api_service.dart';
import 'pokemon_detail_screen.dart';
import 'utils/type_colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Un widget [StatefulWidget] que muestra una sola tarjeta de Pokémon en la lista.
///
/// Se convierte a StatefulWidget para optimizar: la llamada a la API
/// se realiza UNA SOLA VEZ en [initState] y se guarda en el estado,
/// evitando recargas innecesarias al hacer scroll.
class PokemonListCard extends StatefulWidget {
  /// Los datos básicos de la especie (del endpoint 'generation').
  final Map<String, dynamic> pokemonSpecies;

  const PokemonListCard({Key? key, required this.pokemonSpecies})
      : super(key: key);

  @override
  _PokemonListCardState createState() => _PokemonListCardState();
}

class _PokemonListCardState extends State<PokemonListCard> {
  /// Instancia compartida del servicio de API.
  static final ApiService _apiService = ApiService();

  /// Almacena el [Future] que carga los datos de la tarjeta.
  /// Se inicializa en [initState] para prevenir re-ejecuciones.
  late Future<Map<String, dynamic>> _cardDataFuture;

  @override
  void initState() {
    super.initState();
    // Inicia la carga de datos de la tarjeta una sola vez.
    _cardDataFuture = _fetchCardData();
  }

  /// Carga los datos detallados necesarios para esta tarjeta.
  ///
  /// Realiza una cadena de llamadas:
  /// 1. Obtiene el nombre de la especie desde los props del widget.
  /// 2. Busca la 'pokemon-species' para obtener la lista de variedades.
  /// 3. Encuentra la variedad por defecto (ej. 'bulbasaur' y no 'bulbasaur-gmax').
  /// 4. Busca los detalles del 'pokemon' (imágenes, tipos) de esa variedad.
  /// 5. Devuelve un mapa con ambos conjuntos de datos.
  Future<Map<String, dynamic>> _fetchCardData() async {
    final String speciesNameFromEntry = widget.pokemonSpecies['name'];

    final speciesData =
        await _apiService.fetchPokemonSpecies(speciesNameFromEntry);
    final varieties = speciesData['varieties'] as List<dynamic>;
    if (varieties.isEmpty) {
      throw Exception('No varieties found for $speciesNameFromEntry');
    }

    final defaultVariety = varieties.firstWhere(
      (v) => v['is_default'] == true,
      orElse: () => varieties.first,
    );
    final String defaultPokemonName = defaultVariety['pokemon']['name'];
    final pokemonDetails =
        await _apiService.fetchPokemonDetails(defaultPokemonName);

    return {
      'species': speciesData,
      'details': pokemonDetails,
    };
  }

  @override
  Widget build(BuildContext context) {
    /// Construye el [FutureBuilder] que maneja los estados de carga.
    return FutureBuilder<Map<String, dynamic>>(
      // Escucha el Future almacenado en el estado, no una nueva llamada.
      future: _cardDataFuture,
      builder: (context, snapshot) {
        /// Muestra un spinner mientras carga.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        /// Muestra un ícono de error si la API falla.
        if (snapshot.hasError) {
          print(
              'Error cargando datos encadenados para ${widget.pokemonSpecies['name']}: ${snapshot.error}');
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
          );
        }

        /// Maneja el caso de datos nulos o vacíos.
        final pokemonDetails =
            snapshot.data?['details'] as Map<String, dynamic>?;
        final pokemonSpeciesData =
            snapshot.data?['species'] as Map<String, dynamic>?;

        if (pokemonDetails == null || pokemonSpeciesData == null) {
          return Card(child: Center(child: Text('no_data').tr()));
        }

        /// Hace que la tarjeta sea táctil.
        return InkWell(
          onTap: () {
            /// Navega a la [PokemonDetailScreen] al ser presionado.
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
          // Construye el contenido visual de la tarjeta.
          child:
              _buildPokemonCardContent(context, pokemonDetails, pokemonSpeciesData),
        );
      },
    );
  }

  /// Construye el contenido visual de la tarjeta una vez que los datos están disponibles.
  Widget _buildPokemonCardContent(
    BuildContext context,
    Map<String, dynamic> pokemon,
    Map<String, dynamic> species,
  ) {
    // Extracción de datos para el UI.
    final name = species['name'] as String;

    final sprites = pokemon['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork =
        otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final String imageUrl = officialArtwork?['front_default'] as String? ??
        sprites['front_default'] as String? ??
        '';

    final id = species['id'] as int;
    final types = (pokemon['types'] as List<dynamic>)
        .map<String>((type) => type['type']['name'] as String)
        .toList();
    final cardColor = getTypeColor(types.first).withOpacity(0.15);

    // Comprueba si la especie tiene variedades Mega o Gmax.
    bool hasMegaEvolution = false;
    bool hasGmaxEvolution = false;

    if (species.containsKey('varieties')) {
      final varieties = species['varieties'] as List<dynamic>;
      hasMegaEvolution =
          varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
      hasGmaxEvolution =
          varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax'));
    }

    /// El contenedor principal de la tarjeta.
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      /// Usado para superponer los íconos de Mega/Gmax sobre la tarjeta.
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                /// Anima la transición de la imagen a la pantalla de detalle.
                child: Hero(
                  tag: 'pokemon-$id',
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: imageUrl.isEmpty
                        ? Icon(Icons.image_not_supported,
                            size: 60, color: Colors.grey)
                        : Image.network(imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.error_outline, color: Colors.red),
                            loadingBuilder: (c, ch, p) =>
                                p == null ? ch : Center(child: CircularProgressIndicator())),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('#${id.toString().padLeft(3, '0')}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.4))),
                    SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(name[0].toUpperCase() + name.substring(1),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: types
                              .map((type) => _buildTypeChip(type, isSmall: true))
                              .toList()),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),

          /// Posiciona el ícono de Mega Evolución
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

          /// Posiciona el ícono de Gigantamax
          if (hasGmaxEvolution)
            Positioned(
              top: 8,
              left: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.red.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Image.asset(
                    'assets/images/gmax_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir un pequeño chip de tipo (ej. "Planta").
  Widget _buildTypeChip(String type, {bool isSmall = false}) {
    final typeColor = getTypeColor(type);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Chip(
        backgroundColor: typeColor,
        labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8.0 : 12.0),
        padding: EdgeInsets.all(isSmall ? 0 : 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          // Traduce el nombre del tipo (ej. 'types.fire' -> 'Fuego')
          'types.$type'.tr().toUpperCase(),
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
              ]),
        ),
      ),
    );
  }
}