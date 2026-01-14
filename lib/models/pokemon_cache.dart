import 'package:isar/isar.dart';

part 'pokemon_cache.g.dart'; 

@collection
class PokemonCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name; // Índice para buscar por nombre al instante

  late String jsonData; // El contenido del Pokémon en formato texto
}