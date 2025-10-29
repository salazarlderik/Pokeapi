import 'package:flutter/material.dart';
import 'api_service.dart';

class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _pokemonList = [];
  List<dynamic> get pokemonList => _pokemonList;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  PokemonProvider() {
    fetchPokemons();
  }

  Future<void> fetchPokemons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pokemonList = await _apiService.fetchPokemonList();
    } catch (e) {
      // --- TRADUCCIÓN ---
      _error = 'Failed to load Pokémon list. Please check your connection.';
      print('Error fetching Pokémon list: $e'); // Mantenemos el log técnico
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}