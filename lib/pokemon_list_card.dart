import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Nuevo
import 'api_service.dart';
import 'pokemon_detail_screen.dart';
import 'pokemon_extensions.dart';

class PokemonListCard extends StatefulWidget {
  final Map<String, dynamic> pokemonSpecies;
  const PokemonListCard({super.key, required this.pokemonSpecies, required pokemon});

  @override
  State<PokemonListCard> createState() => _PokemonListCardState();
}

class _PokemonListCardState extends State<PokemonListCard> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<List<Map<String, dynamic>>> _loadData() async {
    // Carga paralela de datos
    return Future.wait([
      _apiService.fetchPokemonSpecies(widget.pokemonSpecies['name']),
      _apiService.fetchDefaultPokemonDetailsFromSpecies(widget.pokemonSpecies['name']),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }

        final species = snapshot.data![0];
        final pokemon = snapshot.data![1];
        
        final types = (pokemon['types'] as List).map((t) => t['type']['name'] as String).toList();
        final mainColor = types.first.toTypeColor;
        final id = species['id'];
        final imageUrl = pokemon['sprites']['other']?['official-artwork']?['front_default'] ?? pokemon['sprites']['front_default'] ?? '';

        final varieties = species['varieties'] as List;
        final hasMega = varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega'));
        final hasGmax = varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax'));

        return Card(
          elevation: 3,
          color: mainColor.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(pokemon: pokemon, species: species),
            )),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Hero(
                        tag: 'pokemon-$id',
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          // CAMBIO CLAVE: CachedNetworkImage para velocidad
                          child: imageUrl.isEmpty 
                            ? const Icon(Icons.image_not_supported) 
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
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
                          Text((species['name'] as String).capitalize, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4, runSpacing: 4, alignment: WrapAlignment.center,
                            children: types.map((t) => _buildTypeChip(t)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasMega)
                  Positioned(top: 8, right: 8, child: CircleAvatar(
                    radius: 14, backgroundColor: Colors.black.withOpacity(0.3),
                    child: Padding(padding: const EdgeInsets.all(2), child: Image.asset('assets/images/piedra_activadora.png')),
                  )),
                if (hasGmax)
                  Positioned(top: 8, left: 8, child: CircleAvatar(
                    radius: 14, backgroundColor: Colors.red.withOpacity(0.4),
                    child: Padding(padding: const EdgeInsets.all(2), child: Image.asset('assets/images/gmax_logo.png')),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Chip(
        backgroundColor: type.toTypeColor,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          'types.$type'.tr().toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, shadows: [
            Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.3), offset: const Offset(1, 1)),
          ]),
        ),
      ),
    );
  }
}