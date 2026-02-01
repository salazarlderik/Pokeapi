import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/evolution_helper.dart';
import '../utils/pokemon_extensions.dart';
import '../screens/pokemon_detail_screen.dart';

/// Widget recursivo que visualiza la cadena evolutiva.
/// Maneja estructuras lineales y ramificadas (ej: Eevee, Applin).
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

  /// Construye una rama del árbol evolutivo. Se llama a sí mismo recursivamente
  /// si el Pokémon tiene evoluciones posteriores.
  Widget _buildBranch(Map<String, dynamic> link, String suffix, BuildContext context) {
    String base = link['species']['name'];
    
    // Lógica especial para Lycanroc: La API devuelve "Lycanroc" genérico,
    // aquí forzamos el nombre de la forma específica (Midnight/Dusk) según lo que estemos viendo.
    String pName = EvolutionHelper.getEvoNodeName(base, suffix);
    if (base == 'lycanroc') {
      if (currentPokemonName.contains('midnight')) pName = 'lycanroc-midnight';
      else if (currentPokemonName.contains('dusk')) pName = 'lycanroc-dusk';
      else if (currentPokemonName.contains('midday')) pName = 'lycanroc-midday';
    }

    Widget node = _buildNode(pName, context);
    List evos = link['evolves_to'] ?? [];
    
    // Filtramos evoluciones irrelevantes (ej: Si veo Slowpoke Kanto, oculto Slowbro Galar)
    List filtered = EvolutionHelper.filterEvolutions(evos, base, suffix, currentPokemonName);
    
    // Caso base: Si no tiene evoluciones filtradas, solo devolvemos el nodo actual (imagen).
    if (filtered.isEmpty) return node;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        node,
        // Columna para manejar múltiples ramificaciones (ej: Applin -> Flapple / Appletun)
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          // CLAVE DE DISEÑO: Alineación 'start' para que ramas de diferente longitud
          // (ej: Dipplin vs Flapple) comiencen alineadas a la izquierda y no se vean desordenadas.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filtered.map((e) {
            String targetEvoName = e['species']['name'];
            
            // Padding vertical generoso para separar visualmente las ramas paralelas
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0), 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flecha con condición de evolución (Nivel, Item, etc.)
                  _buildArrow(EvolutionHelper.formatEvoDetails(e['evolution_details'], targetEvoName, suffix)),
                  // Llamada recursiva para construir la siguiente etapa de esta rama
                  _buildBranch(e, suffix, context),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildArrow(String text) => Container(
    width: 110, 
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_forward, color: Colors.grey, size: 20), 
        Text(
          text, 
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87), 
          textAlign: TextAlign.center
        )
      ],
    ),
  );

  /// Construye la tarjeta visual del Pokémon (Imagen + Nombre).
  /// Carga los datos individualmente para obtener el sprite correcto.
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
        // Colorea el borde según el tipo principal del Pokémon
        final color = (data['types'] as List).first['type']['name'].toString().toTypeColor;
        final bool isCur = currentPokemonName == data['name'];

        return GestureDetector(
          // Si tocamos un Pokémon de la cadena (que no sea el actual), navegamos a su pantalla.
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