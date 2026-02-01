import '../utils/pokemon_extensions.dart';

/// Modelo de datos simplificado para usar en la UI.
/// Transforma la respuesta compleja de la API en propiedades directas.
class PokemonModel {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final bool hasMega; // Indicador para mostrar icono de Mega Evolución
  final bool hasGmax; // Indicador para mostrar icono de Gigamax
  
  // Almacenamos el JSON crudo completo para pasarlo a la vista de detalles
  // y evitar realizar una nueva petición HTTP innecesaria.
  final Map<String, dynamic> rawPokemonData;
  final Map<String, dynamic> rawSpeciesData;

  PokemonModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.hasMega,
    required this.hasGmax,
    required this.rawPokemonData,
    required this.rawSpeciesData,
  });

  /// Factory constructor que parsea y unifica los datos de 'pokemon' y 'species'.
  factory PokemonModel.fromApi(Map<String, dynamic> pokemon, Map<String, dynamic> species) {
    // Extracción segura de la estructura de sprites
    final sprites = pokemon['sprites'];
    
    // Lógica de prioridad de imagen: Preferimos "official-artwork" por su alta calidad
    final officialArtwork = sprites['other']?['official-artwork']?['front_default'];
    
    // Obtenemos las variedades para detectar formas especiales (Mega/Gmax)
    final varieties = species['varieties'] as List? ?? [];

    return PokemonModel(
      id: species['id'],
      // Usamos la extensión .capitalize para formatear el nombre para la UI
      name: (species['name'] as String).capitalize,
      // Si no hay arte oficial, hacemos fallback al sprite por defecto
      imageUrl: officialArtwork ?? sprites['front_default'] ?? '',
      // Transformamos la lista compleja de objetos 'type' a una lista simple de Strings
      types: (pokemon['types'] as List).map((t) => t['type']['name'] as String).toList(),
      // Iteramos las variedades buscando palabras clave para activar los indicadores booleanos
      hasMega: varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega')),
      hasGmax: varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax')),
      rawPokemonData: pokemon,
      rawSpeciesData: species,
    );
  }
}