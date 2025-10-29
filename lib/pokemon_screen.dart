import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_detail_screen.dart';
import 'utils/type_colors.dart';

class PokemonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- TRADUCCIÓN ---
        title: Text('Alola Pokémon'), // O 'Pokémon Alola' si prefieres
      ),
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  // --- TRADUCCIÓN ---
                  Text('Loading Alola Pokédex...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            // Ya estaba en inglés, pero aseguramos
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.pokemonList.isEmpty) {
            // Ya estaba en inglés
            return Center(child: Text('No Pokémon found'));
          }

          final pokemonList = provider.pokemonList;

          final screenWidth = MediaQuery.of(context).size.width;
          int crossAxisCount;
          if (screenWidth > 1200) {
            crossAxisCount = 5;
          } else if (screenWidth > 800) {
            crossAxisCount = 4;
          } else if (screenWidth > 500) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2;
          }

          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6, // Mantenemos la última proporción
            ),
            itemCount: pokemonList.length,
            itemBuilder: (context, index) {
              final pokemon = pokemonList[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PokemonDetailScreen(pokemon: pokemon),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: _buildPokemonCard(context, pokemon),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPokemonCard(BuildContext context, Map<String, dynamic> pokemon) {
    final name = pokemon['name'] as String;
    final imageUrl = pokemon['sprites']['other']['official-artwork']
            ['front_default'] ??
        pokemon['sprites']['front_default'];
    
    final id = pokemon['id'] as int;
    // --- TRADUCCIÓN --- (Quitamos el padLeft para un formato más estándar en inglés)
    // final formattedId = id.toString().padLeft(4, '0'); 

    final types = (pokemon['types'] as List<dynamic>)
        .map<String>((type) => type['type']['name'] as String)
        .toList();

    final cardColor = getTypeColor(types.first).withOpacity(0.15);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Hero(
              tag: 'pokemon-$id',
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: (imageUrl != null)
                    ? Image.network( /* ... Imagen ... */ imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s)=>Icon(Icons.error), loadingBuilder: (c,ch,p)=> p==null?ch:Center(child: CircularProgressIndicator()))
                    : Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // --- TRADUCCIÓN --- (Usamos # como es común en inglés)
                  '#$id',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text( /* ... Nombre ... */ name[0].toUpperCase() + name.substring(1), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap( /* ... Tipos ... */ alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: types.map((type) => _buildTypeChip(type, isSmall: true)).toList(),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, {bool isSmall = false}) {
    final typeColor = getTypeColor(type);
    return Padding( /* ... Chip (sin ícono) ... */ padding: EdgeInsets.symmetric(horizontal: 2), child: Chip(backgroundColor: typeColor, labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8.0 : 12.0), padding: EdgeInsets.all(isSmall ? 0 : 2), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, label: Text(type.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12,),),),);
  }
}