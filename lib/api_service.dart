import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  Future<List<dynamic>> fetchPokemonList() async {
    final List<dynamic> pokemonList = [];

    // MODIFICACIÓN: Cambiamos 809 por 741 (Cargará 20 Pokémon)
    for (int id = 722; id <= 741; id++) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/$id'));

        if (response.statusCode == 200) {
          final pokemonData = jsonDecode(response.body);
          pokemonList.add(pokemonData);
        } else {
          // Es buena práctica manejar el error por si una ID falla
          print('Error fetching pokemon $id: ${response.statusCode}');
        }
      } catch (e) {
        print('Exception fetching pokemon $id: $e');
      }
    }

    return pokemonList;
  }
}