import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart'; // 1. Importa Provider
import 'pokemon_provider.dart'; // 2. Importa tu Provider
import 'pokemon_detail_screen.dart'; // 3. Importa la pantalla de detalle

class PokemonScreen extends StatelessWidget {
  // 4. Convertido a StatelessWidget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Generación 7'),
        // 5. El 'actions' de 'sendData' fue eliminado
      ),
      // 6. Usamos Consumer para reaccionar a los cambios del Provider
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          // Muestra un indicador de carga
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Muestra un mensaje de error si ocurre un problema
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          // Muestra un mensaje si no hay datos
          if (provider.pokemonList.isEmpty) {
            return Center(child: Text('No Pokémon found'));
          }

          // Si los datos se cargaron correctamente, muestra la lista
          final pokemonList = provider.pokemonList;

          // --- MEJORA DE RESPONSIVIDAD ---
          // 7. Determinar el número de columnas basado en el ancho
          final screenWidth = MediaQuery.of(context).size.width;
          int crossAxisCount;
          if (screenWidth > 1200) {
            crossAxisCount = 5; // Pantallas muy grandes
          } else if (screenWidth > 800) {
            crossAxisCount = 4; // Tablets
          } else if (screenWidth > 500) {
            crossAxisCount = 3; // Tablets pequeñas / Teléfonos grandes
          } else {
            crossAxisCount = 2; // Teléfonos
          }
          // --- FIN MEJORA RESPONSIVIDAD ---

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // 8. Usamos el valor dinámico
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: pokemonList.length,
            itemBuilder: (context, index) {
              final pokemon = pokemonList[index];

              // 9. Implementamos la navegación
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
                borderRadius: BorderRadius.circular(12),
                child: _buildPokemonCard(pokemon), // 10. Pasamos el mapa completo
              );
            },
          );
        },
      ),
    );
  }

  // 11. Modificamos _buildPokemonCard para aceptar el mapa
  Widget _buildPokemonCard(Map<String, dynamic> pokemon) {
    // Extraemos los datos aquí
    final name = pokemon['name'] as String;
    final imageUrl = pokemon['sprites']['front_default'] as String?;
    final types = (pokemon['types'] as List<dynamic>)
        .map<String>((type) => type['type']['name'] as String)
        .toList();
    final abilities = (pokemon['abilities'] as List<dynamic>)
        .map<String>((ability) => ability['ability']['name'] as String)
        .toList();
    final isHidden = (pokemon['abilities'] as List<dynamic>)
        .map<bool>((ability) => ability['is_hidden'] as bool)
        .toList();

    final normalAbilities = <String>[];
    final hiddenAbilities = <String>[];
    for (int i = 0; i < abilities.length; i++) {
      if (isHidden[i]) {
        hiddenAbilities.add(abilities[i]);
      } else {
        normalAbilities.add(abilities[i]);
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 40, color: Colors.red);
                },
              )
            else
              Icon(Icons.image, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              name.toUpperCase(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1, // Evita desbordamiento de nombres largos
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: types.map((type) {
                final typeImageUrl =
                    'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    color: _getTypeColor(type),
                    padding: EdgeInsets.all(4),
                    child: SvgPicture.network(
                      typeImageUrl,
                      width: 24,
                      height: 24,
                      placeholderBuilder: (context) =>
                          Icon(Icons.image, size: 24, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (normalAbilities.isNotEmpty)
                    Text(
                      'Habilidades: ${normalAbilities.join(', ')}',
                      style: TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hiddenAbilities.isNotEmpty)
                    Text(
                      'Oculta: ${hiddenAbilities.join(', ')}',
                      style: TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 12. Esta función debe estar aquí (o en un archivo de utilidades)
  Color _getTypeColor(String type) {
    switch (type) {
      case 'grass':
        return Colors.green;
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.purple;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pink;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.orange;
      case 'flying':
        return Colors.lightBlue[300]!;
      case 'poison':
        return Colors.purple[800]!;
      case 'ground':
        return Colors.brown[400]!;
      case 'rock':
        return Colors.brown[600]!;
      case 'bug':
        return Colors.lightGreen[500]!;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}