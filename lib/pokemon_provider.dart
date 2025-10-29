import 'package:flutter/material.dart';
import 'api_service.dart';

/// Gestiona el estado relacionado con la lista de Pokémon.
class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _pokemonList = [];
  /// Lista pública de Pokémon.
  List<dynamic> get pokemonList => _pokemonList;

  bool _isLoading = true;
  /// Indica si se están cargando los datos.
  bool get isLoading => _isLoading;

  String? _error;
  /// Mensaje de error si la carga falló.
  String? get error => _error;

  /// Constructor: Inicia la carga de datos al crearse.
  PokemonProvider() {
    fetchPokemons();
  }

  /// Obtiene los Pokémon usando ApiService y actualiza el estado.
  Future<void> fetchPokemons() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Avisa a los widgets que la carga empezó.

    try {
      _pokemonList = await _apiService.fetchPokemonList();
    } catch (e) {
      _error = 'Failed to load Pokémon list. Please check your connection.';
      print('Error al obtener la lista de Pokémon: $e'); // Log interno
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisa a los widgets que la carga terminó (con éxito o error).
    }
  }
}