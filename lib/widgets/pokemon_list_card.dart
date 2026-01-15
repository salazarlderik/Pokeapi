import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../screens/pokemon_detail_screen.dart';
import '../utils/pokemon_extensions.dart';

class PokemonListCard extends StatefulWidget {
  final Map<String, dynamic> pokemonSpecies; 
  const PokemonListCard({super.key, required this.pokemonSpecies});

  @override
  State<PokemonListCard> createState() => _PokemonListCardState();
}

class _PokemonListCardState extends State<PokemonListCard> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      _apiService.fetchPokemonSpecies(widget.pokemonSpecies['name']),
      _apiService.fetchDefaultPokemonDetailsFromSpecies(widget.pokemonSpecies['name']),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Card(child: Center(child: CircularProgressIndicator()));

        final species = snapshot.data![0];
        final pokemon = snapshot.data![1];
        final types = (pokemon['types'] as List).map((t) => t['type']['name'] as String).toList();
        
        final String firstType = types.first.toLowerCase();
        final Color mainColor = firstType.toTypeColor;

        // --- JERARQUÍA DE OPACIDADES ACTUALIZADA ---
        double backgroundOpacity = 0.15; // Planta, Psíquico y Normal

        if (firstType == 'rock' ) {
          backgroundOpacity = 0.48; // Los más fuertes y oscuros
        } else if (firstType == 'fairy') {
          backgroundOpacity = 0.25; // Hada potente
        } else if (firstType == 'bug') {
          backgroundOpacity = 0.40; // BICHO: El más claro de la tarjeta
        } else if (firstType == 'ice') {
          backgroundOpacity = 0.30;}
          else if (firstType == 'poison') {
          backgroundOpacity = 0.30;}
          else if (firstType == 'flying') {
          backgroundOpacity = 0.60;}
          else if (firstType == 'dark') {
          backgroundOpacity = 0.10;}
        
        final varieties = species['varieties'] as List;
        final hasMega = varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
        final hasGmax = varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax'));

        return Card(
          elevation: 4,
          color: mainColor.withValues(alpha: backgroundOpacity),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PokemonDetailScreen(pokemon: pokemon, species: species))),
            child: Stack(
              children: [
                // Resplandor trasero (Ajustado según opacidad de la tarjeta)
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
                
                // Iconos Mega/Gmax (Tamaño 25 y margen 10)
                if (hasMega) Positioned(top: 10, right: 10, child: Image.asset('assets/images/piedra_activadora.png', width: 25)),
                if (hasGmax) Positioned(top: 10, left: 10, child: Image.asset('assets/images/gmax_logo.png', width: 25)),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Hero(
                        tag: 'pokemon-${species['id']}',
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CachedNetworkImage(
                            imageUrl: pokemon['sprites']['other']?['official-artwork']?['front_default'] ?? '',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text((species['name'] as String).capitalize, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.toTypeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'types.$type'.tr().toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
      ),
    );
  }
}