import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../screens/pokemon_detail_screen.dart';
import '../utils/pokemon_extensions.dart';

/// Tarjeta individual que se muestra en la grilla principal.
/// Maneja la carga de datos específicos (detalles y especie) de forma asíncrona.
class PokemonListCard extends StatefulWidget {
  final Map<String, dynamic> pokemonSpecies; 
  final String suffix; 
  
  const PokemonListCard({super.key, required this.pokemonSpecies, this.suffix = ""});

  @override
  State<PokemonListCard> createState() => _PokemonListCardState();
}

class _PokemonListCardState extends State<PokemonListCard> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // Lanzamos ambas peticiones en paralelo para optimizar la carga.
    // Usamos el sufijo para obtener la forma regional correcta desde el inicio.
    _dataFuture = Future.wait([
      _apiService.fetchPokemonSpecies(widget.pokemonSpecies['name']),
      _apiService.fetchDefaultPokemonDetailsFromSpecies(
        widget.pokemonSpecies['name'], 
        suffix: widget.suffix
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // Estado de carga inicial
        if (!snapshot.hasData) return const Card(child: Center(child: CircularProgressIndicator()));

        final species = snapshot.data![0];
        final pokemon = snapshot.data![1];
        
        // Extraemos los tipos para definir el color de la tarjeta
        final types = (pokemon['types'] as List).map((t) => t['type']['name'] as String).toList();
        final String firstType = types.first.toLowerCase();
        final Color mainColor = firstType.toTypeColor;

        // --- LÓGICA DE DISEÑO VISUAL ---
        // Ajustamos la opacidad del fondo según el tipo para que el contraste sea agradable.
        double backgroundOpacity = 0.15;
        if (firstType == 'rock') backgroundOpacity = 0.48;
        else if (firstType == 'fairy') backgroundOpacity = 0.25;
        else if (firstType == 'bug') backgroundOpacity = 0.40;
        else if (firstType == 'ice' || firstType == 'poison') backgroundOpacity = 0.30;
        else if (firstType == 'flying') backgroundOpacity = 0.60;
        else if (firstType == 'dark') backgroundOpacity = 0.6;
        else if (firstType == 'normal') backgroundOpacity = 0.1;
        
        // Detectamos variedades especiales (Mega/Gmax) para mostrar sus indicadores
        final varieties = species['varieties'] as List;
        final hasMega = varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
        final hasGmax = varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax'));

        return Card(
          elevation: 4,
          color: mainColor.withValues(alpha: backgroundOpacity),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => PokemonDetailScreen(pokemon: pokemon, species: species))
            ),
            child: Stack(
              children: [
                // Círculo decorativo de fondo (Efecto de brillo)
                Positioned(
                  top: -10, right: -10,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          mainColor.withValues(alpha: (backgroundOpacity > 0.15 ? 0.5 : 0.4)),
                          mainColor.withValues(alpha: 0.0)
                        ]
                      ),
                    ),
                  ),
                ),

                // Iconos indicadores de formas especiales
                if (hasMega) Positioned(top: 10, right: 10, child: Image.asset('assets/images/piedra_activadora.png', width: 25)),
                if (hasGmax) Positioned(top: 10, left: 10, child: Image.asset('assets/images/gmax_logo.png', width: 25)),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Área de la Imagen con Hero para animación suave
                    Expanded(
                      flex: 3,
                      child: Hero(
                        tag: 'pokemon-${species['id']}',
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CachedNetworkImage(
                            // Priorizamos el arte oficial por su alta definición
                            imageUrl: pokemon['sprites']['other']?['official-artwork']?['front_default'] ?? '',
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Área de Información (Nombre y Tipos)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (species['name'] as String).capitalize, 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            alignment: WrapAlignment.center,
                            children: types.map((t) => _buildTypeChip(t)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye un chip pequeño para representar el tipo del Pokémon.
  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.toTypeColor, 
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text(
        'types.$type'.tr().toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
      ),
    );
  }
}