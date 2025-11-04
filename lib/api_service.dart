import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para interactuar con la PokeAPI.
class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  /// Obtiene los detalles de un rango específico de Pokémon (por IDs).
  Future<List<dynamic>> fetchPokemonListByRange(int startId, int endId) async {
    final List<dynamic> pokemonList = [];
    final List<Future<http.Response>> futures = [];

    // Prepara las peticiones para el rango de IDs solicitado.
    for (int id = startId; id <= endId; id++) {
      futures.add(http.get(Uri.parse('$_baseUrl/$id')));
    }

    try {
      // Ejecuta todas las peticiones concurrentemente.
      final responses = await Future.wait(futures);

      for (var response in responses) {
        if (response.statusCode == 200) {
          final pokemonData = jsonDecode(response.body);
          pokemonList.add(pokemonData);
        } else {
          print('Error fetching pokemon: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Exception during parallel fetch: $e');
      throw Exception('Failed to load Pokémon list');
    }

    pokemonList.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return pokemonList;
  }
}