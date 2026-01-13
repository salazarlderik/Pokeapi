import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static final Map<String, Map<String, dynamic>> _memCache = {};
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<dynamic>> fetchGenerationEntries(int generationId) async {
    final response = await http.get(Uri.parse('$_baseUrl/generation/$generationId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['pokemon_species'] as List<dynamic>;
    }
    throw Exception('Failed to load generation');
  }

  // Métodos rápidos que usan el caché
  Future<Map<String, dynamic>> fetchPokemonDetails(String name) async => _fetchWithCache('poke_$name', '$_baseUrl/pokemon/$name');
  Future<Map<String, dynamic>> fetchPokemonSpecies(String name) async => _fetchWithCache('spec_$name', '$_baseUrl/pokemon-species/$name');

  Future<Map<String, dynamic>> _fetchWithCache(String key, String url) async {
    // Prioridad 1: RAM (Instantáneo)
    if (_memCache.containsKey(key)) return _memCache[key]!;

    // Prioridad 2: Disco del teléfono
    final cachedData = _prefs?.getString(key);
    if (cachedData != null) {
      final decoded = jsonDecode(cachedData);
      _memCache[key] = decoded;
      return decoded;
    }

    // Prioridad 3: Internet
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // OPTIMIZACIÓN: Guardamos en RAM primero para que la UI no espere
      _memCache[key] = data;
      
      // Guardamos en disco de forma asíncrona (SIN AWAIT) para no trabar la carga
      _prefs?.setString(key, jsonEncode(data)); 
      
      return data;
    }
    throw Exception('Error de red');
  }

  Future<Map<String, dynamic>> fetchDefaultPokemonDetailsFromSpecies(String name) async {
    final species = await fetchPokemonSpecies(name);
    final varieties = species['varieties'] as List;
    final defaultName = varieties.firstWhere((v) => v['is_default'] == true, orElse: () => varieties.first)['pokemon']['name'];
    return await fetchPokemonDetails(defaultName);
  }

  Future<Map<String, dynamic>> fetchEvolutionChain(String url) async {
    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }
}