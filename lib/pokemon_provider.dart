import 'package:flutter/material.dart';
import 'api_service.dart'; // Importa tu servicio

class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado de la lista de Pokémon
  List<dynamic> _pokemonList = [];
  List<dynamic> get pokemonList => _pokemonList;

  // Estado de carga
  bool _isLoading = true; // Inicia en true para la carga inicial
  bool get isLoading => _isLoading;

  // Estado de error
  String? _error;
  String? get error => _error;

  /// Constructor: Inicia la carga de datos automáticamente
  PokemonProvider() {
    fetchPokemons();
  }

  /// Método para obtener los Pokémon usando el ApiService
  Future<void> fetchPokemons() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica a los widgets que estamos cargando

    try {
      // Llama al servicio para obtener los datos
      _pokemonList = await _apiService.fetchPokemonList();
    } catch (e) {
      // Maneja cualquier error que ocurra durante el fetching
      _error = e.toString();
    } finally {
      // Sin importar si hubo éxito o error, dejamos de cargar
      _isLoading = false;
      notifyListeners(); // Notifica a los widgets el estado final
    }
  }
}