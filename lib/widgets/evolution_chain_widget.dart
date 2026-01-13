import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/evolution_helper.dart';
import '../utils/pokemon_extensions.dart';
import '../screens/pokemon_detail_screen.dart';

class EvolutionChainWidget extends StatelessWidget {
  final Map<String, dynamic> chain;
  final String regionSuffix;
  final String currentPokemonName;

  const EvolutionChainWidget({
    super.key, 
    required this.chain, 
    required this.regionSuffix,
    required this.currentPokemonName,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBranch(chain, regionSuffix, context);
  }

  Widget _buildBranch(Map<String, dynamic> link, String suffix, BuildContext context) {
    String base = link['species']['name'];
    String pName = EvolutionHelper.getEvoNodeName(base, suffix);
    Widget node = _buildNode(pName, context);

    List evos = link['evolves_to'] ?? [];
    List filtered = EvolutionHelper.filterEvolutions(evos, base, suffix);
    
    if (filtered.isEmpty) return node;

    return Row(
      mainAxisSize: MainAxisSize.min, // Crucial para el centrado
      children: [
        node,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: filtered.map((e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildArrow(EvolutionHelper.formatEvoDetails(e['evolution_details'], e['species']['name'])),
              _buildBranch(e, suffix, context),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildArrow(String text) => Container(
    width: 100,
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_forward, color: Colors.grey), 
        Text(
          text, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), 
          textAlign: TextAlign.center
        )
      ],
    ),
  );

  Widget _buildNode(String name, BuildContext context) {
    final api = ApiService();
    return FutureBuilder<Map<String, dynamic>>(
      future: name.contains('-') ? api.fetchPokemonDetails(name) : api.fetchDefaultPokemonDetailsFromSpecies(name),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(width: 80, height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        
        final data = snap.data!;
        final color = (data['types'] as List).first['type']['name'].toString().toTypeColor;
        final isCur = currentPokemonName == data['name'];

        return GestureDetector(
          onTap: isCur ? null : () async {
            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            final s = await api.fetchPokemonSpecies(data['name']);
            final p = await api.fetchPokemonDetails(data['name']);
            if (!context.mounted) return;
            Navigator.pop(context);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PokemonDetailScreen(pokemon: p, species: s)));
          },
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isCur ? color.withOpacity(0.1) : Colors.white.withOpacity(0.5), 
              border: Border.all(color: isCur ? color : Colors.grey.shade300, width: 2), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              children: [
                Image.network(data['sprites']['front_default'] ?? '', height: 70, fit: BoxFit.contain),
                Text(
                  data['name'].toString().cleanName, 
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}