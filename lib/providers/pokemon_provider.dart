import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PokemonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isDisposed = false; 

  List<dynamic> _allPokemon = []; 
  String _searchQuery = "";
  String? _selectedType;
  
  // Cache para guardar los tipos y poder filtrar localmente sin llamar a la API cada vez
  final Map<String, List<String>> _pokemonTypesMap = {};
  
  // Sufijo regional (ej: '-alola') vital para pedir la variante correcta a la API
  String _currentRegionSuffix = "";
  String get currentRegionSuffix => _currentRegionSuffix;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;

  // Lógica principal de filtrado para la UI
  List<dynamic> get filteredPokemon {
    // 1. Si hay tipo seleccionado, filtramos usando el mapa de tipos en memoria
    if (_selectedType != null) {
      return _allPokemon.where((p) {
        final types = _pokemonTypesMap[p['name']];
        return types?.contains(_selectedType) ?? false;
      }).toList();
    }
    // 2. Si hay búsqueda, filtramos por nombre o ID
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
    // Determinamos el sufijo para manejar formas regionales (Alola, Galar, Hisui, Paldea)
    if (regionFilter == 'galar') _currentRegionSuffix = '-galar';
    else if (regionFilter == 'hisui') _currentRegionSuffix = '-hisui';
    else if (generationId == 7) _currentRegionSuffix = '-alola';
    else if (generationId == 9) _currentRegionSuffix = '-paldea';
    else _currentRegionSuffix = '';

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

  void resetToDefault() {
    _selectedType = null;
    _searchQuery = "";
    notifyListeners();
  }

  Future<void> fetchGeneration(int generationId, {String? regionFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<dynamic> entries = await _apiService.fetchGenerationEntries(generationId);
      
      // Ordenamos numéricamente por ID (la API a veces los devuelve desordenados)
      entries.sort((a, b) {
        final idA = int.parse(a['url'].split('/').reversed.elementAt(1));
        final idB = int.parse(b['url'].split('/').reversed.elementAt(1));
        return idA.compareTo(idB);
      });

      // Filtro especial Gen 8: Separamos Galar y Hisui basándonos en rangos de ID
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

  // Carga los tipos en segundo plano usando el sufijo para obtener la variante correcta
  Future<void> _loadTypesInBackground() async {
    for (var p in _allPokemon) {
      if (_isDisposed) return;
      try {
        final d = await _apiService.fetchDefaultPokemonDetailsFromSpecies(
          p['name'], 
          suffix: _currentRegionSuffix // Clave para obtener tipos regionales (ej: Vulpix Alola)
        );
        if (_isDisposed) return;
        _pokemonTypesMap[p['name']] = (d['types'] as List).map((t) => t['type']['name'] as String).toList();
      } catch (_) {}
    }
    notifyListeners(); 
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