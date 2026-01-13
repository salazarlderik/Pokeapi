import 'package:flutter/material.dart';
import 'api_service.dart';

class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _pokemonEntries = [];
  List<dynamic> get pokemonEntries => _pokemonEntries;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  PokemonProvider({required int generationId, String? regionFilter}) {
    fetchGeneration(generationId, regionFilter: regionFilter);
  }

  Future<void> fetchGeneration(int generationId, {String? regionFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<dynamic> allEntries = await _apiService.fetchGenerationEntries(generationId);
      
      allEntries.sort((a, b) {
        final idA = int.parse(a['url'].split('/').reversed.elementAt(1));
        final idB = int.parse(b['url'].split('/').reversed.elementAt(1));
        return idA.compareTo(idB);
      });

      if (generationId == 8 && regionFilter != null) {
        _pokemonEntries = allEntries.where((e) {
          final id = int.parse(e['url'].split('/').reversed.elementAt(1));
          return regionFilter == 'galar' ? (id >= 810 && id <= 898) : (id >= 899 && id <= 905);
        }).toList();
      } else {
        _pokemonEntries = allEntries;
      }
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}