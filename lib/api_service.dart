import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  Future<List<dynamic>> fetchPokemonList() async {
    final List<dynamic> pokemonList = [];
    final List<Future<http.Response>> futures = [];
    for (int id = 722; id <= 809; id++) {
      futures.add(http.get(Uri.parse('$_baseUrl/$id')));
    }

    try {
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
      // --- TRADUCCIÓN ---
      throw Exception('Failed to load Pokémon list');
    }

    pokemonList.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return pokemonList;
  }
}