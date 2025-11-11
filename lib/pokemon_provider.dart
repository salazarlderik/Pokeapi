import 'package:flutter/material.dart';
import 'api_service.dart';

/// Gestiona el estado de la lista de Pokémon para una región/generación.
///
/// Utiliza [ChangeNotifier] para notificar a los widgets (como [PokemonScreen])
/// sobre cambios en el estado (carga, error, o datos listos).
class PokemonProvider extends ChangeNotifier {
  /// Instancia del servicio de API para hacer las llamadas de red.
  final ApiService _apiService = ApiService();

  /// La lista de entradas de especies de Pokémon.
  List<dynamic> _pokemonEntries = [];
  List<dynamic> get pokemonEntries => _pokemonEntries;

  /// Bandera para mostrar un indicador de carga en el UI.
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Mensaje de error, si alguno ocurre.
  String? _error;
  String? get error => _error;

  /// Constructor que inicia la carga de datos inmediatamente.
  ///
  /// [generationId] es el ID de la generación a cargar (ej. 1, 2, 7).
  /// [regionFilter] es opcional, usado para dividir Gen 8 en 'galar' o 'hisui'.
  PokemonProvider({required int generationId, String? regionFilter}) {
    fetchGeneration(generationId, regionFilter: regionFilter);
  }

  /// Carga la lista de Pokémon desde la API para la [generationId] dada.
  ///
  /// Opcionalmente filtra la lista si se provee un [regionFilter].
  Future<void> fetchGeneration(int generationId, {String? regionFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica a los listeners que la carga ha comenzado

    try {
      // Obtiene la lista completa de la generación
      List<dynamic> allEntries =
          await _apiService.fetchGenerationEntries(generationId);

      // La API de generación a veces devuelve las especies desordenadas (ej. Gen 8).
      // Las ordenamos por el ID de la especie extraído de la URL.
      allEntries.sort((a, b) {
        final urlA = a['url'] as String;
        final urlB = b['url'] as String;
        // Extrae el ID de la URL (ej. .../pokemon-species/25/)
        final idA = int.parse(urlA.split('/')[urlA.split('/').length - 2]);
        final idB = int.parse(urlB.split('/')[urlB.split('/').length - 2]);
        return idA.compareTo(idB);
      });

      // Lógica de filtrado especial para Generación 8 (Galar/Hisui)
      if (generationId == 8 && regionFilter != null) {
        if (regionFilter == 'galar') {
          // IDs 810 (Grookey) a 898 (Calyrex)
          _pokemonEntries = allEntries.where((e) {
            final url = e['url'] as String;
            final id = int.parse(url.split('/')[url.split('/').length - 2]);
            return id >= 810 && id <= 898;
          }).toList();
        } else if (regionFilter == 'hisui') {
          // IDs 899 (Wyrdeer) a 905 (Enamorus)
          _pokemonEntries = allEntries.where((e) {
            final url = e['url'] as String;
            final id = int.parse(url.split('/')[url.split('/').length - 2]);
            return id >= 899 && id <= 905;
          }).toList();
        } else {
          _pokemonEntries = allEntries;
        }
      } else {
        // Para todas las demás generaciones, usa la lista completa
        _pokemonEntries = allEntries;
      }
    } catch (e) {
      _error = 'Failed to load Pokédex. Please check your connection.';
      print('Error al obtener la Generación: $e'); // Log para depuración
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica que la carga ha terminado (con éxito o error)
    }
  }
}