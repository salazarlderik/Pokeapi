import 'package:flutter/material.dart';
import 'api_service.dart';

/// Gestiona el estado de UNA lista de Pokémon (ej. una región).
class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _pokemonList = [];
  List<dynamic> get pokemonList => _pokemonList;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _selectedTypeFilter;
  String? get selectedTypeFilter => _selectedTypeFilter;

  Set<String> _availableTypes = {};
  List<String> get availableTypes => _availableTypes.toList()..sort();

  /// El constructor ahora recibe el rango y comienza la carga.
  PokemonProvider({required int startId, required int endId}) {
    fetchPokemons(startId, endId);
  }

  /// Obtiene los Pokémon para el rango especificado.
  Future<void> fetchPokemons(int startId, int endId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Llama al servicio con el rango.
      _pokemonList = await _apiService.fetchPokemonListByRange(startId, endId);
      _extractAvailableTypes();
    } catch (e) {
      _error = 'Failed to load Pokémon list. Please check your connection.';
      print('Error al obtener la lista de Pokémon: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el tipo seleccionado para el filtro y notifica a los widgets.
  void filterByType(String? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  /// Devuelve la lista filtrada.
  List<dynamic> get filteredPokemonList {
    if (_selectedTypeFilter == null) {
      return _pokemonList;
    } else {
      return _pokemonList.where((pokemon) {
        final types = (pokemon['types'] as List<dynamic>)
            .map<String>((typeInfo) => typeInfo['type']['name'] as String)
            .toList();
        return types.contains(_selectedTypeFilter);
      }).toList();
    }
  }

  /// Método auxiliar para extraer y almacenar los tipos únicos.
  void _extractAvailableTypes() {
    _availableTypes.clear();
    for (var pokemon in _pokemonList) {
      final types = (pokemon['types'] as List<dynamic>)
          .map<String>((typeInfo) => typeInfo['type']['name'] as String);
      _availableTypes.addAll(types);
    }
  }
}