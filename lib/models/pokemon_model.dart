import '../utils/pokemon_extensions.dart';

class PokemonModel {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final bool hasMega;
  final bool hasGmax;
  // Guardamos los datos crudos para pasarlos a la pantalla de detalle sin volver a llamar a la API
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

  factory PokemonModel.fromApi(Map<String, dynamic> pokemon, Map<String, dynamic> species) {
    final sprites = pokemon['sprites'];
    final officialArtwork = sprites['other']?['official-artwork']?['front_default'];
    final varieties = species['varieties'] as List? ?? [];

    return PokemonModel(
      id: species['id'],
      name: (species['name'] as String).capitalize,
      imageUrl: officialArtwork ?? sprites['front_default'] ?? '',
      types: (pokemon['types'] as List).map((t) => t['type']['name'] as String).toList(),
      hasMega: varieties.any((v) => (v['pokemon']['name'] as String).contains('-mega')),
      hasGmax: varieties.any((v) => (v['pokemon']['name'] as String).contains('-gmax')),
      rawPokemonData: pokemon,
      rawSpeciesData: species,
    );
  }
}