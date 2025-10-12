import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL base de la PokeAPI para obtener información de Pokémon
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  // Método para obtener una lista de Pokémon
  Future<List<dynamic>> fetchPokemonList() async {
    final List<dynamic> pokemonList = []; // Lista para almacenar los datos de los Pokémon

    // Itera sobre un rango de IDs de Pokémon (desde 722 hasta 809)
    for (int id = 722; id <= 809; id++) {
      // Realiza una petición GET a la API para obtener los datos de un Pokémon específico
      final response = await http.get(Uri.parse('$_baseUrl/$id'));

      // Verifica si la petición fue exitosa (código 200 significa "OK")
      if (response.statusCode == 200) {
        final pokemonData = jsonDecode(response.body);
        pokemonList.add(pokemonData); // Agrega los datos del Pokémon a la lista
      }
    }

    return pokemonList; 
  }
}