import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para interactuar con la PokeAPI.
class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  Future<List<dynamic>> fetchPokemonList() async {
    final List<dynamic> pokemonList = [];
    final List<Future<http.Response>> futures = [];

    // Prepara todas las peticiones HTTP sin ejecutarlas todavia.
    for (int id = 722; id <= 809; id++) {
      futures.add(http.get(Uri.parse('$_baseUrl/$id')));
    }

    try {
      // Ejecuta todas las peticiones al mismo tiempo para mayor velocidad.
      final responses = await Future.wait(futures);

      // Procesa las respuestas una vez que todas han llegado.
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
      throw Exception('Failed to load Pokémon list'); // Mensaje de error en inglés
    }

    // Ordena la lista por ID.
    pokemonList.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return pokemonList;
  }
}