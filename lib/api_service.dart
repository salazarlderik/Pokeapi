import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para interactuar con la PokeAPI.
/// Maneja todas las solicitudes de red.
class ApiService {
  /// URL base para todos los endpoints de la PokeAPI v2.
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  /// Obtiene la lista de "especies de pokémon" de una generación específica.
  Future<List<dynamic>> fetchGenerationEntries(int generationId) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/generation/$generationId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['pokemon_species'] as List<dynamic>;
    } else {
      throw Exception('Failed to load Generation entries for $generationId');
    }
  }

  /// Obtiene los detalles completos (imagen, tipos) de un solo Pokémon por su nombre.
  /// Este endpoint usa el nombre del 'pokemon' (ej. 'bulbasaur', 'lycanroc-midnight').
  Future<Map<String, dynamic>> fetchPokemonDetails(String pokemonName) async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon/$pokemonName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load details for $pokemonName');
    }
  }

  /// Obtiene los datos de la "especie" (donde están las variedades y cadena evolutiva).
  /// Este endpoint usa el nombre de la 'pokemon-species' (ej. 'bulbasaur', 'lycanroc').
  Future<Map<String, dynamic>> fetchPokemonSpecies(String pokemonName) async {
    String baseName = pokemonName;

    /// Lógica para eliminar sufijos de formas (ej. '-alola', '-gmax')
    /// y encontrar el nombre de la especie base.
    /// Es necesario porque la API usa 'pokemon-species/lycanroc'
    /// incluso para 'lycanroc-midnight'.
    const knownSuffixes = [
      '-alola', '-galar', '-hisui', '-paldea',
      '-standard', '-zen', '-gmax',
      '-own-tempo',
      // Sufijos de género y forma que SÍ queremos quitar
      '-male', '-female',
      '-two-segment', '-three-segment'
      // Se quitaron: -midday, -midnight, -dusk. ¡Esos son nombres de Pokémon!
    ];

    for (var suffix in knownSuffixes) {
      if (pokemonName.endsWith(suffix)) {
        baseName = pokemonName.substring(0, pokemonName.length - suffix.length);
        // Maneja casos dobles como 'darmanitan-galar-standard' -> 'darmanitan'
        if (baseName.endsWith('-galar')) {
          baseName = baseName.substring(0, baseName.length - '-galar'.length);
        }
        break;
      }
    }

    final response =
        await http.get(Uri.parse('$_baseUrl/pokemon-species/$baseName'));
        
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // Fallback: Si 'pokemon-species/basculegion-male' falla (404),
      // prueba con 'pokemon-species/basculin' (que es lo que hace el strip)

      // Si el baseName y el pokemonName son iguales (ej. 'lycanroc-midnight')
      // y falla, es porque no es una especie, sino una forma de 'pokemon'.
      if (baseName == pokemonName) {
        // Intenta buscar el nombre original como especie de todos modos
        final response2 = await http
            .get(Uri.parse('$_baseUrl/pokemon-species/$pokemonName'));
        if (response2.statusCode == 200) {
          return jsonDecode(response2.body) as Map<String, dynamic>;
        }
        throw Exception('Failed to load species for $baseName (Not a species)');
      }

      // Si eran diferentes (ej. 'basculegion-male' -> 'basculin')
      // y 'basculin' falló, entonces algo anda mal.
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

  /// Obtiene los detalles del Pokémon "por defecto" para una especie.
  ///
  /// Maneja casos complejos donde el nombre de entrada puede ser una forma específica
  /// (ej. 'lycanroc-midnight') O una especie base (ej. 'pikachu').
  /// Intenta una carga directa primero, si falla, busca la variedad "is_default"
  /// desde los datos de la especie.
  Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(
      String pokemonName) async {
    try {
      // 1. Intenta cargar el nombre EXACTO como un 'pokemon'.
      // Esto funcionará para 'lycanroc-midnight', 'dudunsparce-two-segment', etc.
      return await fetchPokemonDetails(pokemonName);
    } catch (e) {
      // 2. Si falla (porque SÍ es un nombre de 'pokemon-species', como "basculin", "pikachu")
      print(
          "fetchDefaultPokemonDetailsFromSpecies: Falló la carga directa de '$pokemonName'. Probando lógica de especie.");

      try {
        // fetchPokemonSpecies usará la lógica de sufijos para encontrar la especie base
        final speciesData = await fetchPokemonSpecies(pokemonName);
        final varieties = speciesData['varieties'] as List<dynamic>;
        if (varieties.isEmpty) {
          throw Exception('No varieties found for $pokemonName');
        }

        // Encuentra la variedad marcada como 'is_default'
        final defaultVariety = varieties.firstWhere(
          (v) => v['is_default'] == true,
          orElse: () => varieties.first,
        );

        String defaultPokemonName = defaultVariety['pokemon']['name'];

        // FIX ESPECIAL DUDUNSPARCE:
        // La API dice que el default de 'dudunsparce' (especie) es 'dudunsparce' (pokemon),
        // lo cual es un bucle infinito. Forzamos la forma de dos segmentos.
        if (pokemonName == 'dudunsparce' &&
            defaultPokemonName == 'dudunsparce') {
          defaultPokemonName = 'dudunsparce-two-segment';
        }

        // Carga los detalles de la forma por defecto
        return await fetchPokemonDetails(defaultPokemonName);
      } catch (e2) {
        print(
            "fetchDefaultPokemonDetailsFromSpecies: Falló también la lógica de especie para '$pokemonName'. $e2");
        throw Exception(
            'Failed to load details for $pokemonName by any method.');
      }
    }
  }
}