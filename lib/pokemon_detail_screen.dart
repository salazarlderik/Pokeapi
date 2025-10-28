import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PokemonDetailScreen extends StatelessWidget {
  // Recibimos el mapa completo del Pokémon
  final Map<String, dynamic> pokemon;

  const PokemonDetailScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extrayendo datos
    final String name = pokemon['name'];
    // Intenta usar la imagen oficial (es de mejor calidad)
    final String imageUrl =
        pokemon['sprites']['other']['official-artwork']['front_default'] ??
            pokemon['sprites']['front_default'];

    final types = (pokemon['types'] as List<dynamic>)
        .map<String>((type) => type['type']['name'] as String)
        .toList();

    final abilities = (pokemon['abilities'] as List<dynamic>)
        .map<String>((ability) => ability['ability']['name'] as String)
        .toList();

    final int height = pokemon['height']; // Altura en decímetros
    final int weight = pokemon['weight']; // Peso en hectogramos

    return Scaffold(
      appBar: AppBar(
        // Capitaliza el nombre para el título
        title: Text(name[0].toUpperCase() + name.substring(1)),
        backgroundColor: _getTypeColor(types.first), // Color basado en el primer tipo
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Imagen del Pokémon
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error, size: 200, color: Colors.red);
                  },
                )
              else
                Icon(Icons.image, size: 200, color: Colors.grey),

              SizedBox(height: 16),

              // 2. Nombre
              Text(
                name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              SizedBox(height: 8),

              // 3. Tipos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: types.map((type) => _buildTypeChip(type)).toList(),
              ),

              SizedBox(height: 24),

              // 4. Información adicional (Peso y Altura)
              _buildStatInfo('Peso', '${weight / 10} kg'), // Convertir a kg
              _buildStatInfo('Altura', '${height / 10} m'), // Convertir a m

              SizedBox(height: 24),

              // 5. Habilidades
              Text(
                'Habilidades',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: abilities
                    .map((ability) => Chip(
                          label: Text(ability),
                          backgroundColor: Colors.grey[200],
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para mostrar la info de peso y altura
  Widget _buildStatInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Widget helper para mostrar los tipos
  Widget _buildTypeChip(String type) {
    final typeColor = _getTypeColor(type);
    final typeImageUrl =
        'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        backgroundColor: typeColor,
        label: Text(
          type.toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        avatar: SvgPicture.network(
          typeImageUrl,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  // Nota: Esta función está duplicada.
  // En un proyecto real, la moverías a 'lib/utils/type_colors.dart'
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