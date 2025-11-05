import 'package:flutter/material.dart';
import 'api_service.dart';

/// Gestiona el estado relacionado con la lista de especies de una generación.
class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Lista de "especies de pokémon" (contiene nombre y URL, no detalles).
  List<dynamic> _pokemonEntries = [];
  List<dynamic> get pokemonEntries => _pokemonEntries;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Constructor: Inicia la carga de datos al crearse.
  /// Requiere el ID de la generación (ej. 1, 2, 7).
  PokemonProvider({required int generationId}) {
    fetchGeneration(generationId);
  }

  /// Obtiene las especies de la generación usando ApiService.
  Future<void> fetchGeneration(int generationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Llama al nuevo método del servicio.
      _pokemonEntries = await _apiService.fetchGenerationEntries(generationId);

      // La API de generación a veces devuelve las especies desordenadas (ej. Gen 8).
      // Las ordenamos por el ID que extraemos de la URL.
      _pokemonEntries.sort((a, b) {
        final urlA = a['url'] as String;
        final urlB = b['url'] as String;
        // Extrae el ID de la URL (ej. .../pokemon-species/25/)
        final idA = int.parse(urlA.split('/')[urlA.split('/').length - 2]);
        final idB = int.parse(urlB.split('/')[urlB.split('/').length - 2]);
        return idA.compareTo(idB);
      });
      
    } catch (e) {
      _error = 'Failed to load Pokédex. Please check your connection.';
      print('Error al obtener la Generación: $e'); // Log interno
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}