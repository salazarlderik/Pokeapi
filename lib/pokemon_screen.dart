import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_detail_screen.dart';
import 'utils/type_colors.dart';

/// Muestra la cuadrícula de Pokémon para UNA región específica.
class PokemonScreen extends StatelessWidget {
  /// El nombre de la región, pasado desde RegionScreen.
  final String regionName;

  const PokemonScreen({Key? key, required this.regionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtiene el provider que fue creado en RegionScreen.
    final provider = Provider.of<PokemonProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(regionName), // Muestra el nombre de la región.
      ),
      // Columna para poner el filtro encima de la cuadrícula.
      body: Column(
        children: [
          _buildFilterDropdown(context, provider),
          Expanded(
            child: _buildPokemonGrid(context, provider),
          ),
        ],
      ),
    );
  }

  /// Construye el widget DropdownButton para el filtro de tipos.
  Widget _buildFilterDropdown(BuildContext context, PokemonProvider provider) {
    if (provider.isLoading || provider.availableTypes.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButton<String?>(
        value: provider.selectedTypeFilter,
        isExpanded: true,
        hint: Text('Filter by Type...'),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('All Types'),
          ),
          ...provider.availableTypes.map((type) {
            return DropdownMenuItem<String?>(
              value: type,
              child: Row(
                children: [
                  _buildTypeChip(type, isSmall: true), // Reutiliza el helper.
                  SizedBox(width: 8),
                  Text(type[0].toUpperCase() + type.substring(1)),
                ],
              ),
            );
          }).toList(),
        ],
        onChanged: (String? newType) {
          context.read<PokemonProvider>().filterByType(newType);
        },
      ),
    );
  }

  /// Construye la cuadrícula de Pokémon.
  Widget _buildPokemonGrid(BuildContext context, PokemonProvider provider) {
    if (provider.isLoading) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading Pokédex...'), // Mensaje de carga genérico
      ]));
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    final pokemonList = provider.filteredPokemonList;

    if (pokemonList.isEmpty) {
      return Center(child: Text(provider.selectedTypeFilter == null
          ? 'No Pokémon found'
          : 'No ${provider.selectedTypeFilter} type Pokémon found'
          ));
    }

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
        crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        final pokemon = pokemonList[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PokemonDetailScreen(pokemon: pokemon))),
          borderRadius: BorderRadius.circular(16),
          child: _buildPokemonCard(context, pokemon),
        );
      },
    );
  }

  /// Construye la tarjeta individual de un Pokémon.
  Widget _buildPokemonCard(BuildContext context, Map<String, dynamic> pokemon) {
    final name = pokemon['name'] as String;
    final imageUrl = pokemon['sprites']['other']['official-artwork']['front_default'] ?? pokemon['sprites']['front_default'];
    final id = pokemon['id'] as int;
    final types = (pokemon['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final cardColor = getTypeColor(types.first).withOpacity(0.15);

    return Card(
      elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor, clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded( flex: 3, child: Hero(tag: 'pokemon-$id', child: Padding( padding: const EdgeInsets.all(12.0), child: (imageUrl != null) ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.error), loadingBuilder: (c, ch, p) => p == null ? ch : Center(child: CircularProgressIndicator())) : Icon(Icons.image, size: 60, color: Colors.grey),),),),
          Expanded( flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('#$id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.4))),
                SizedBox(height: 4),
                Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(name[0].toUpperCase() + name.substring(1), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,),),
                SizedBox(height: 8),
                Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: types.map((type) => _buildTypeChip(type, isSmall: true)).toList(),),),
              ],),),
        ],
      ),
    );
  }

  /// Construye un Chip simple para mostrar un tipo.
  Widget _buildTypeChip(String type, {bool isSmall = false}) {
    final typeColor = getTypeColor(type);
    return Padding( padding: EdgeInsets.symmetric(horizontal: 2), child: Chip(backgroundColor: typeColor, labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8.0 : 12.0), padding: EdgeInsets.all(isSmall ? 0 : 2), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, label: Text(type.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12,),),),);
  }
}