import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para interactuar con la PokeAPI.
class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  /// Obtiene las "especies de pokémon" de una generación específica.
  Future<List<dynamic>> fetchGenerationEntries(int generationId) async {
    final response = await http.get(Uri.parse('$_baseUrl/generation/$generationId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
    
    // ==================================================
    // 👇 ¡LÓGICA MEJORADA! Arregla Metang, Mr. Rime, Nidoran, etc.
    // ==================================================
    String baseName = pokemonName;

    // ==================================================
    // 👇 ¡CORRECCIÓN DE LYCANROC!
    //    Quitamos '-midday', '-midnight', '-dusk' de esta lista.
    //    Esos SÍ son nombres de Pokémon, y no queremos
    //    quitarlos para buscar la especie "lycanroc".
    // ==================================================
    const knownSuffixes = [
      '-alola', '-galar', '-hisui', '-paldea', 
      '-standard', '-zen', '-gmax', 
      // '-midday', '-midnight', '-dusk', // <- ¡ELIMINADOS!
      '-own-tempo'
    ];
    
    // Solo modificamos el nombre si TERMINA con un sufijo conocido.
    for (var suffix in knownSuffixes) {
      if (pokemonName.endsWith(suffix)) {
        // Quita el sufijo
        baseName = pokemonName.substring(0, pokemonName.length - suffix.length);
        // Caso especial: darmanitan-galar-standard -> darmanitan
        if (baseName.endsWith('-galar')) {
            baseName = baseName.substring(0, baseName.length - '-galar'.length);
        }
        break; // Sufijo encontrado y quitado, salimos del bucle
      }
    }
    // ==================================================

    final response = await http.get(Uri.parse('$_baseUrl/pokemon-species/$baseName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // Si falla (ej. pokemon-species/lycanroc-midnight da 404),
      // intentamos con el nombre original.
      final response2 = await http.get(Uri.parse('$_baseUrl/pokemon-species/$pokemonName'));
      if (response2.statusCode == 200) {
        return jsonDecode(response2.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to load species for $baseName (from $pokemonName)');
    }
  }

  /// Obtiene una cadena de evolución por su URL específica.
  Future<Map<String, dynamic>> fetchEvolutionChain(String chainUrl) async {
    final response = await http.get(Uri.parse(chainUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load evolution chain from $chainUrl');
    }
  }

  /// Obtiene los detalles del Pokémon por defecto a partir de un nombre de ESPECIE.
  Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(String pokemonName) async {
    try {
      // 1. Intenta cargar el nombre EXACTO como un Pokémon.
      // ¡AHORA ESTO FUNCIONARÁ PARA LYCANROC-MIDNIGHT!
      return await fetchPokemonDetails(pokemonName);

    } catch (e) {
      // 2. Si falla (porque es un nombre de ESPECIE, como "basculin"),
      //    intenta la lógica de "especie -> variedad por defecto".
      print("fetchDefaultPokemonDetailsFromSpecies: Falló la carga directa de '$pokemonName'. Probando lógica de especie.");
      
      try {
        // fetchPokemonSpecies AHORA buscará "lycanroc-midnight"
        // y como fallará, intentará "lycanroc-midnight" otra vez (lo cual está bien)
        // o podemos hacer que busque el nombre base
        final speciesData = await fetchPokemonSpecies(pokemonName); 
        final varieties = speciesData['varieties'] as List<dynamic>;
        if (varieties.isEmpty) {
          throw Exception('No varieties found for $pokemonName');
        }

        final defaultVariety = varieties.firstWhere(
          (v) => v['is_default'] == true,
          orElse: () => varieties.first,
        );
        
        final String defaultPokemonName = defaultVariety['pokemon']['name'];
        return await fetchPokemonDetails(defaultPokemonName);

      } catch (e2) {
        print("fetchDefaultPokemonDetailsFromSpecies: Falló también la lógica de especie para '$pokemonName'. $e2");
        throw Exception('Failed to load details for $pokemonName by any method.');
      }
    }
  }
}