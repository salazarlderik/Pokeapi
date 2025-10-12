import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  final ApiService _apiService = ApiService(); // Instancia del servicio de API
  late Future<List<dynamic>> _pokemonListFuture; // Futuro para almacenar la lista de Pokémon

  @override
  void initState() {
    super.initState();
    _pokemonListFuture = _apiService.fetchPokemonList();
  }

  // Método para enviar datos mediante una petición POST
  Future<void> sendData() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts'); // Url
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'}, // Cabeceras para indicar que el cuerpo es JSON
      body: jsonEncode({
        'title': 'Pokémon App',
        'body': 'Pokemon prueba.',
        'userId': 1,
      }),
    );

    // Verifica si la petición fue exitosa (código 201 significa "Created")
    if (response.statusCode == 201) {
      print('Datos enviados correctamente: ${response.body}');
    } else {
      throw Exception('Error al enviar los datos: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Generación 7'), 
        actions: [
          // Botón para enviar datos
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              try {
                await sendData(); // Llama al método para enviar datos
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Datos enviados correctamente')), 
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')), // Muestra un SnackBar de error
                );
              }
            },
          ),
        ],
      ),
      // FutureBuilder para manejar la carga de la lista de Pokémon
      body: FutureBuilder<List<dynamic>>(
        future: _pokemonListFuture,
        builder: (context, snapshot) {
          // Muestra un indicador de carga mientras se obtienen los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Muestra un mensaje de error si ocurre un problema
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Muestra un mensaje si no hay datos
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Pokémon found'));
          }
          // Si los datos se cargaron correctamente, muestra la lista de Pokémon
          else {
            final pokemonList = snapshot.data!;
            return GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Número de columnas en la cuadrícula
                crossAxisSpacing: 16, // Espaciado horizontal entre elementos
                mainAxisSpacing: 16, // Espaciado vertical entre elementos
                childAspectRatio: 0.7, // Relación de aspecto de los elementos
              ),
              itemCount: pokemonList.length, // Número de Pokémon en la lista
              itemBuilder: (context, index) {
                final pokemon = pokemonList[index];
                final imageUrl = pokemon['sprites']['front_default']; // URL de la imagen del Pokémon
                final types = (pokemon['types'] as List<dynamic>)
                    .map<String>((type) => type['type']['name'] as String)
                    .toList(); // Lista de tipos del Pokémon
                final abilities = (pokemon['abilities'] as List<dynamic>)
                    .map<String>((ability) => ability['ability']['name'] as String)
                    .toList(); // Lista de habilidades del Pokémon
                final isHidden = (pokemon['abilities'] as List<dynamic>)
                    .map<bool>((ability) => ability['is_hidden'] as bool)
                    .toList(); // Lista de habilidades ocultas

                // Separa las habilidades normales de las ocultas
                final normalAbilities = <String>[];
                final hiddenAbilities = <String>[];
                for (int i = 0; i < abilities.length; i++) {
                  if (isHidden[i]) {
                    hiddenAbilities.add(abilities[i]);
                  } else {
                    normalAbilities.add(abilities[i]);
                  }
                }

                // Construye la tarjeta de cada Pokémon
                return _buildPokemonCard(
                  name: pokemon['name'],
                  imageUrl: imageUrl,
                  types: types,
                  normalAbilities: normalAbilities,
                  hiddenAbilities: hiddenAbilities,
                );
              },
            );
          }
        },
      ),
    );
  }

  // Método para construir la tarjeta de un Pokémon
  Widget _buildPokemonCard({
    required String name,
    required String? imageUrl,
    required List<String> types,
    required List<String> normalAbilities,
    required List<String> hiddenAbilities,
  }) {
    return Card(
      elevation: 4, // Elevación de la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordes redondeados
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Muestra la imagen del Pokémon o un ícono de error si no está disponible
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
            // Muestra el nombre del Pokémon en mayúsculas
            Text(
              name.toUpperCase(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            // Muestra los tipos del Pokémon con íconos SVG
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: types.map((type) {
                final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    color: _getTypeColor(type), // Color de fondo según el tipo
                    padding: EdgeInsets.all(4),
                    child: SvgPicture.network(
                      typeImageUrl,
                      width: 24,
                      height: 24,
                      placeholderBuilder: (context) => Icon(Icons.image, size: 24, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            // Muestra las habilidades del Pokémon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (normalAbilities.isNotEmpty)
                    Text(
                      'Habilidades: ${normalAbilities.join(', ')}',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (hiddenAbilities.isNotEmpty)
                    Text(
                      'Habilidad Oculta: ${hiddenAbilities.join(', ')}',
                      style: TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener el color asociado a un tipo de Pokémon
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