import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isDisposed = false; 

  List<dynamic> _allPokemon = []; 
  String _searchQuery = "";
  String? _selectedType;
  final Map<String, List<String>> _pokemonTypesMap = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;

  List<dynamic> get filteredPokemon {
    if (_selectedType != null) {
      return _allPokemon.where((p) {
        final types = _pokemonTypesMap[p['name']];
        return types?.contains(_selectedType) ?? false;
      }).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      return _allPokemon.where((p) {
        final name = p['name'].toString().toLowerCase();
        final id = p['url'].split('/').reversed.elementAt(1);
        return name.startsWith(q) || id == q;
      }).toList();
    }
    return _allPokemon;
  }

  PokemonProvider({required int generationId, String? regionFilter}) {
    fetchGeneration(generationId, regionFilter: regionFilter);
  }

  @override
  void dispose() {
    _isDisposed = true; 
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  // --- REINICIO SILENCIOSO (Para cuando usamos la flecha de regreso) ---
  void resetToDefault() {
    _selectedType = null;
    _searchQuery = "";
    // No notificamos aquí para evitar choques con la navegación
  }

  Future<void> fetchGeneration(int generationId, {String? regionFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<dynamic> entries = await _apiService.fetchGenerationEntries(generationId);
      entries.sort((a, b) {
        final idA = int.parse(a['url'].split('/').reversed.elementAt(1));
        final idB = int.parse(b['url'].split('/').reversed.elementAt(1));
        return idA.compareTo(idB);
      });

      _allPokemon = (generationId == 8 && regionFilter != null)
          ? entries.where((e) {
              final id = int.parse(e['url'].split('/').reversed.elementAt(1));
              return regionFilter == 'galar' ? (id >= 810 && id <= 898) : (id >= 899 && id <= 905);
            }).toList()
          : entries;

      _isLoading = false;
      notifyListeners();
      _loadTypesInBackground();
    } catch (e) {
      _error = 'Error de conexión';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTypesInBackground() async {
    for (var p in _allPokemon) {
      if (_isDisposed) return;
      try {
        final d = await _apiService.fetchDefaultPokemonDetailsFromSpecies(p['name']);
        if (_isDisposed) return; // Doble check para evitar error de JNI
        _pokemonTypesMap[p['name']] = (d['types'] as List).map((t) => t['type']['name'] as String).toList();
        await Future.delayed(const Duration(milliseconds: 15)); 
      } catch (_) {}
    }
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _selectedType = null; 
    notifyListeners();
  }

  void updateType(String? type) {
    _selectedType = type;
    _searchQuery = ""; 
    notifyListeners();
  }
}