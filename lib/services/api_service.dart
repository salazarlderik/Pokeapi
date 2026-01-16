import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/pokemon_cache.dart';
import '../main.dart';

class ApiService {
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

  // --- ACTUALIZADO: Ahora prioriza la variedad regional según el sufijo ---
  // Busca esta función en tu ApiService y cámbiala por esta versión exacta:
Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(String speciesName, {String suffix = ""}) async {
  try {
    final species = await fetchPokemonSpecies(speciesName);
    final varieties = species['varieties'] as List;

    // Si estamos en Alola/Galar/etc, buscamos el nombre con el sufijo primero
    if (suffix.isNotEmpty) {
      final regionalName = "$speciesName$suffix";
      // Intentamos buscar directamente por el nombre regional para saltar el "default" de Kanto
      try {
        return await fetchPokemonDetails(regionalName);
      } catch (_) {
        // Si falla, buscamos en la lista de variedades la que contenga el sufijo
        final regional = varieties.firstWhere(
          (v) => (v['pokemon']['name'] as String).contains(suffix),
          orElse: () => null,
        );
        if (regional != null) return await fetchPokemonDetails(regional['pokemon']['name']);
      }
    }
    
    final defaultVar = varieties.firstWhere((v) => v['is_default'] == true, orElse: () => varieties.first);
    return await fetchPokemonDetails(defaultVar['pokemon']['name']);
  } catch (e) {
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