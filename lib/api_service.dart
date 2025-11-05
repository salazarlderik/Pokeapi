import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para interactuar con la PokeAPI.
class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  /// Obtiene las "especies de pokémon" de una generación específica (ej. 1 para Kanto).
  /// Esto es rápido y devuelve la lista de especies de esa generación.
  Future<List<dynamic>> fetchGenerationEntries(int generationId) async {
    final response = await http.get(Uri.parse('$_baseUrl/generation/$generationId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Devolvemos la lista de 'pokemon_species'
      return data['pokemon_species'] as List<dynamic>;
    } else {
      throw Exception('Failed to load Generation entries for $generationId');
    }
  }

  /// Obtiene los detalles completos (imagen, tipos) de un solo Pokémon por su nombre.
  Future<Map<String, dynamic>> fetchPokemonDetails(String pokemonName) async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon/$pokemonName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load details for $pokemonName');
    }
  }

  /// Obtiene los datos de la "especie" (donde están las variedades, como Megas).
  Future<Map<String, dynamic>> fetchPokemonSpecies(String pokemonName) async {
    
    // --- INICIO DE LA CORRECCIÓN ---
    // Ya no cortamos el nombre. El 'pokemonName' que viene de la lista
    // de generación (ej. 'jangmo-o', 'tapu-koko', 'type-null') es el correcto.
    //
    // String baseName = pokemonName.split('-').first; // <- LÍNEA ELIMINADA

    // Usamos 'pokemonName' directamente en la URL
    final response = await http.get(Uri.parse('$_baseUrl/pokemon-species/$pokemonName'));
    // --- FIN DE LA CORRECCIÓN ---

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // --- CORRECCIÓN EN EL ERROR ---
      // Mostramos el nombre original que falló
      throw Exception('Failed to load species for $pokemonName');
      // --- FIN CORRECCIÓN ERROR ---
    }
  }
}