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
    
    // Sincronización para Lycanroc
    String pName = EvolutionHelper.getEvoNodeName(base, suffix);
    if (base == 'lycanroc') {
      if (currentPokemonName.contains('midnight')) pName = 'lycanroc-midnight';
      else if (currentPokemonName.contains('dusk')) pName = 'lycanroc-dusk';
      else if (currentPokemonName.contains('midday')) pName = 'lycanroc-midday';
    }

    Widget node = _buildNode(pName, context);
    List evos = link['evolves_to'] ?? [];
    
    List filtered = EvolutionHelper.filterEvolutions(evos, base, suffix, currentPokemonName);
    
    if (filtered.isEmpty) return node;

    return Row(
      mainAxisSize: MainAxisSize.min,
      // ALINEACIÓN VERTICAL CENTRAL PARA TODA LA FILA
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        node,
        Column(
          mainAxisSize: MainAxisSize.min,
          // AQUÍ ESTÁ EL ARREGLO DE ALINEACIÓN PARA APPLIN
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: filtered.map((e) {
            String targetEvoName = e['species']['name'];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildArrow(EvolutionHelper.formatEvoDetails(e['evolution_details'], targetEvoName, suffix)),
                _buildBranch(e, suffix, context),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildArrow(String text) => Container(
    width: 100,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_forward, color: Colors.grey, size: 20), 
        Text(
          text, 
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87), 
          textAlign: TextAlign.center
        )
      ],
    ),
  );

  Widget _buildNode(String name, BuildContext context) {
    final api = ApiService();
    return FutureBuilder<Map<String, dynamic>>(
      future: name.contains('-') 
          ? api.fetchPokemonDetails(name) 
          : api.fetchDefaultPokemonDetailsFromSpecies(name),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(width: 80, height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        
        final data = snap.data!;
        final color = (data['types'] as List).first['type']['name'].toString().toTypeColor;
        final bool isCur = currentPokemonName == data['name'];

        return GestureDetector(
          onTap: isCur ? null : () async {
            showDialog(
              context: context, 
              barrierDismissible: false, 
              builder: (_) => const Center(child: CircularProgressIndicator())
            );
            
            try {
              final s = await api.fetchPokemonSpecies(data['name']);
              final p = await api.fetchPokemonDetails(data['name']);
              if (!context.mounted) return;
              Navigator.pop(context); 
              
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => PokemonDetailScreen(pokemon: p, species: s))
              );
            } catch (e) {
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Container(
            width: 90,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isCur ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5), 
              border: Border.all(color: isCur ? color : Colors.grey.shade300, width: 2), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              children: [
                Image.network(
                  data['sprites']['front_default'] ?? '', 
                  height: 60, 
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.help_outline, size: 40),
                ),
                Text(
                  data['name'].toString().cleanName, 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                  maxLines: 1,
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