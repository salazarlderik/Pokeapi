import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_list_card.dart'; // Importa el nuevo widget de tarjeta

/// Muestra la cuadrícula de Pokémon para UNA región específica.
class PokemonScreen extends StatelessWidget {
  final String regionName;

  const PokemonScreen({Key? key, required this.regionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(regionName), // Muestra el nombre de la región
      ),
      // Ya no necesitamos una Column, solo el Consumer.
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          // Muestra indicador mientras carga la LISTA de entradas.
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  // Texto de UI en Inglés
                  Text('Loading ${regionName.split('(').first} Pokédex...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          
          if (provider.pokemonEntries.isEmpty) {
            return Center(child: Text('No Pokémon found in this region.'));
          }

          // La lista de entradas (nombres y URLs).
          final pokemonEntries = provider.pokemonEntries;

          // Calcula columnas responsivas.
          final screenWidth = MediaQuery.of(context).size.width;
          int crossAxisCount;
          if (screenWidth > 1200) { crossAxisCount = 5; }
          else if (screenWidth > 800) { crossAxisCount = 4; }
          else if (screenWidth > 500) { crossAxisCount = 3; }
          else { crossAxisCount = 2; }

          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7, // La proporción que ajustaste
            ),
            itemCount: pokemonEntries.length,
            itemBuilder: (context, index) {
              
              // --- INICIO DE LA CORRECCIÓN ---
              // 'entry' ya es el mapa {'name': 'bulbasaur', 'url': ...}
              // Hacemos un cast seguro.
              final entry = pokemonEntries[index] as Map<String, dynamic>;
              
              // No necesitamos acceder a 'pokemon_species' dentro de 'entry'.
              // 'entry' ES 'pokemonSpecies'.
              
              return PokemonListCard(
                pokemonSpecies: entry, // Pasamos 'entry' directamente
              );
              // --- FIN DE LA CORRECCIÓN ---
            },
          );
        },
      ),
    );
  }
}