import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/pokemon_cache.dart';
import '../main.dart';

class ApiService {
  // Obtiene los detalles de un Pokémon específico
  Future<Map<String, dynamic>> fetchPokemonDetails(String name) async {
    final cached = await isar.pokemonCaches.filter().nameEqualTo(name).findFirst();
    if (cached != null) return jsonDecode(cached.jsonData);

    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'));
    if (response.statusCode == 200) {
      final newCache = PokemonCache()..name = name..jsonData = response.body;
      await isar.writeTxn(() async => await isar.pokemonCaches.put(newCache));
      return jsonDecode(response.body);
    }
    throw Exception('Error 404: $name no encontrado');
  }

  // Obtiene la información de la especie
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

  // --- CORRECCIÓN: Resuelve el nombre real del Pokémon por defecto ---
  Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(String speciesName) async {
    try {
      // 1. Obtenemos la especie primero
      final species = await fetchPokemonSpecies(speciesName);
      
      // 2. Buscamos en las variedades cuál es la 'is_default'
      final varieties = species['varieties'] as List;
      final defaultVar = varieties.firstWhere((v) => v['is_default'] == true, orElse: () => varieties.first);
      final realPokemonName = defaultVar['pokemon']['name'];

      // 3. Descargamos los detalles usando el nombre real
      return await fetchPokemonDetails(realPokemonName);
    } catch (e) {
      // Fallback si algo falla
      return await fetchPokemonDetails(speciesName);
    }
  }

  Future<List<dynamic>> fetchGenerationEntries(int id) async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/generation/$id'));
    if (response.statusCode == 200) return jsonDecode(response.body)['pokemon_species'];
    throw Exception('Error en Generation');
  }

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