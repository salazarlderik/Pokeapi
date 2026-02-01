import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/pokemon_cache.dart';
import '../main.dart';

/// Servicio central encargado de la comunicación con la PokeAPI y el almacenamiento local.
/// Implementa una estrategia "Cache-First": Primero busca en la DB local (Isar), si falla, va a internet.
class ApiService {

  /// Obtiene los detalles técnicos de un Pokémon (Stats, Tipos, Sprites).
  /// [name] puede ser el nombre base ('pikachu') o una variante ('pikachu-gmax').
  Future<Map<String, dynamic>> fetchPokemonDetails(String name) async {
    // 1. Verificamos si ya tenemos este JSON guardado en el celular
    final cached = await isar.pokemonCaches.filter().nameEqualTo(name).findFirst();
    if (cached != null) return jsonDecode(cached.jsonData);

    // 2. Si no, hacemos la petición a la API
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'));
    if (response.statusCode == 200) {
      // 3. Guardamos la respuesta en Isar para la próxima vez (funciona offline)
      final newCache = PokemonCache()..name = name..jsonData = response.body;
      await isar.writeTxn(() async => await isar.pokemonCaches.put(newCache));
      return jsonDecode(response.body);
    }
    throw Exception('Error 404: $name no encontrado');
  }

  /// Obtiene datos de la especie (Flavor text, URL de evolución, lista de variedades).
  /// Usa el prefijo "species_" en la caché para no chocar con los datos de `fetchPokemonDetails`.
  Future<Map<String, dynamic>> fetchPokemonSpecies(String name) async {
    final cacheKey = "species_$name";
    final cached = await isar.pokemonCaches.filter().nameEqualTo(cacheKey).findFirst();
    if (cached != null) return jsonDecode(cached.jsonData);

    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$name'));
    if (response.statusCode == 200) {
      final newCache = PokemonCache()..name = cacheKey..jsonData = response.body;
      await isar.writeTxn(() async => await isar.pokemonCaches.put(newCache));
      return jsonDecode(response.body);
    }
    throw Exception('Error en Species: $name');
  }

  /// Método inteligente para resolver qué "Forma" del Pokémon mostrar.
  /// Si se proporciona un [suffix] (ej: '-hisui'), intenta forzar la carga de esa variante regional.
  /// Si no, carga la variante marcada como 'is_default' (la original).
  Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(String speciesName, {String suffix = ""}) async {
    try {
      final species = await fetchPokemonSpecies(speciesName);
      final varieties = species['varieties'] as List;

      // Lógica de Prioridad Regional:
      if (suffix.isNotEmpty) {
        final regionalName = "$speciesName$suffix";
        // Intento 1: Buscar directamente por nombre concatenado (ej: 'growlithe-hisui')
        try {
          return await fetchPokemonDetails(regionalName);
        } catch (_) {
          // Intento 2: Buscar dentro de la lista de variedades si el nombre directo falla
          final regional = varieties.firstWhere(
            (v) => (v['pokemon']['name'] as String).contains(suffix),
            orElse: () => null,
          );
          if (regional != null) return await fetchPokemonDetails(regional['pokemon']['name']);
        }
      }
      
      // Fallback: Si no hay sufijo o no se encuentra la variante, usamos la default
      final defaultVar = varieties.firstWhere((v) => v['is_default'] == true, orElse: () => varieties.first);
      return await fetchPokemonDetails(defaultVar['pokemon']['name']);
    } catch (e) {
      // Último recurso de seguridad
      return await fetchPokemonDetails(speciesName);
    }
  }

  /// Obtiene la lista maestra de especies para una generación.
  /// Se usa para poblar la GridView inicial.
  Future<List<dynamic>> fetchGenerationEntries(int id) async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/generation/$id'));
    if (response.statusCode == 200) return jsonDecode(response.body)['pokemon_species'];
    throw Exception('Error en Generation');
  }

  /// Obtiene el árbol evolutivo completo.
  /// Extrae el ID numérico de la [url] proporcionada por la especie para generar la clave de caché.
  Future<Map<String, dynamic>> fetchEvolutionChain(String url) async {
    final id = url.split('/').reversed.elementAt(1);
    final cacheKey = "evo_$id";
    
    final cached = await isar.pokemonCaches.filter().nameEqualTo(cacheKey).findFirst();
    if (cached != null) return jsonDecode(cached.jsonData);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final newCache = PokemonCache()..name = cacheKey..jsonData = response.body;
      await isar.writeTxn(() async => await isar.pokemonCaches.put(newCache));
      return jsonDecode(response.body);
    }
    throw Exception('Error en Evolution');
  }
}