import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_list_card.dart';
import 'package:easy_localization/easy_localization.dart';

/// Muestra la cuadrícula de Pokémon para una región específica.
/// Escucha a [PokemonProvider] para su estado.
class PokemonScreen extends StatelessWidget {
  /// La clave de traducción para el nombre de la región (ej. 'regions.kanto').
  final String regionNameKey;

  const PokemonScreen({Key? key, required this.regionNameKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /// El título se traduce usando la clave (ej. 'Kanto', 'Johto').
        title: Text(regionNameKey).tr(),
        actions: [
          /// Botón para cambiar el idioma de la aplicación.
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              if (context.locale == Locale('en')) {
                context.setLocale(Locale('es'));
              } else {
                context.setLocale(Locale('en'));
              }
            },
          ),
        ],
      ),
      /// [Consumer] se redibuja cuando [PokemonProvider] notifica cambios.
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          /// Estado de Carga: Muestra un spinner.
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  /// Muestra "Cargando Pokédex de Kanto..."
                  Text('loading_pokedex'
                      .tr(args: [regionNameKey.tr()])),
                ],
              ),
            );
          }

          /// Estado de Error: Muestra el mensaje de error.
          if (provider.error != null) {
            return Center(
                child: Text('error_prefix'.tr() + (provider.error ?? '')));
          }

          /// Estado Vacío: Muestra un mensaje si no hay datos.
          if (provider.pokemonEntries.isEmpty) {
            return Center(child: Text('no_pokemon_found').tr());
          }

          /// Estado con Datos: Construye la cuadrícula.
          final pokemonEntries = provider.pokemonEntries;

          /// Lógica para un layout responsive.
          /// Ajusta el número de columnas basado en el ancho de la pantalla.
          final screenWidth = MediaQuery.of(context).size.width;
          int crossAxisCount;
          if (screenWidth > 1200) {
            crossAxisCount = 5;
          } else if (screenWidth > 800) {
            crossAxisCount = 4;
          } else if (screenWidth > 500) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2; // Default para móviles
          }

          /// La cuadrícula principal de Pokémon.
          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7, // Tarjetas más altas que anchas
            ),
            itemCount: pokemonEntries.length,
            itemBuilder: (context, index) {
              final entry = pokemonEntries[index] as Map<String, dynamic>;
              /// Cada ítem es una [PokemonListCard] que maneja su propia carga.
              return PokemonListCard(
                pokemonSpecies: entry,
              );
            },
          );
        },
      ),
    );
  }
}