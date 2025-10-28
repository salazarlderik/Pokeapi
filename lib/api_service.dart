import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  Future<List<dynamic>> fetchPokemonList() async {
    final List<dynamic> pokemonList = [];

    // 1. Crear una lista de peticiones (Futures) sin 'await'
    // Cargaremos la Pokédex de Alola completa (ID 722 a 809)
    final List<Future<http.Response>> futures = [];
    for (int id = 722; id <= 809; id++) {
      futures.add(http.get(Uri.parse('$_baseUrl/$id')));
    }

    try {
      // 2. Ejecutar todas las peticiones en paralelo
      final responses = await Future.wait(futures);

      // 3. Procesar las respuestas
      for (var response in responses) {
        if (response.statusCode == 200) {
          final pokemonData = jsonDecode(response.body);
          pokemonList.add(pokemonData);
        } else {
          // Manejar el error de una petición individual
          print('Error fetching pokemon: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Manejar el error si Future.wait() falla
      print('Exception during parallel fetch: $e');
      throw Exception('Failed to load Pokémon list');
    }

    // Ordenar la lista por ID, ya que la carga paralela no garantiza el orden
    pokemonList.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    return pokemonList;
  }
}