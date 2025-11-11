import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_screen.dart';
import 'package:easy_localization/easy_localization.dart';

/// Pantalla principal que muestra la lista de regiones de Pokémon.
/// Cada región es un [Card] táctil que navega a [PokemonScreen].
class RegionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /// Título traducido de la app.
        title: Text('app_title_header').tr(),
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
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          /// Lista de todas las regiones.
          /// Se pasa la clave de traducción, el ID de generación y el nombre de la imagen.
          _buildRegionTile(context, 'regions.kanto', 1, 'kanto.PNG'),
          _buildRegionTile(context, 'regions.johto', 2, 'jotho.png'),
          _buildRegionTile(context, 'regions.hoenn', 3, 'hoenn.png'),
          _buildRegionTile(context, 'regions.sinnoh', 4, 'sinnoh.png'),
          _buildRegionTile(context, 'regions.unova', 5, 'unova.png'),
          _buildRegionTile(context, 'regions.kalos', 6, 'kalos.PNG'),
          _buildRegionTile(context, 'regions.alola', 7, 'alola.png'),
          
          /// Galar y Hisui (ambos Gen 8) se separan usando un [regionFilter].
          _buildRegionTile(context, 'regions.galar', 8, 'galar.PNG', regionFilter: 'galar'),
          _buildRegionTile(context, 'regions.hisui', 8, 'hisui.png', regionFilter: 'hisui'),
          
          _buildRegionTile(context, 'regions.paldea', 9, 'paldea.PNG'),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir cada [Card] táctil de región.
  Widget _buildRegionTile(
    BuildContext context, 
    String displayKey, 
    int generationId, 
    String imageName, 
    {String? regionFilter} // Filtro opcional para Galar/Hisui
  ) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Asegura que la imagen respete los bordes redondeados
      child: InkWell(
        onTap: () {
          /// Al tocar, navega a [PokemonScreen] proveyendo un nuevo [PokemonProvider].
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                /// Crea el provider, pasando el ID de generación y el filtro opcional.
                create: (context) => PokemonProvider(
                  generationId: generationId,
                  regionFilter: regionFilter,
                ),
                /// La pantalla hija que consumirá el provider.
                child: PokemonScreen(regionNameKey: displayKey),
              ),
            ),
          );
        },
        /// [Stack] permite superponer el texto sobre la imagen con degradado.
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            /// Imagen de fondo de la región.
            Ink.image(
              image: AssetImage('assets/images/$imageName'),
              height: 100,
              fit: BoxFit.cover,
              /// Manejo de error si la imagen no carga.
              onImageError: (exception, stackTrace) {
                print("Error loading image $imageName: $exception");
              },
            ),
            /// Degradado oscuro para asegurar que el texto blanco sea legible.
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [ Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.1) ],
                ),
              ),
            ),
            /// Contenido de texto (Nombre de la región).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    /// Traduce la clave (ej. 'regions.kanto' -> 'Kanto').
                    displayKey.tr(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5))]),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withOpacity(0.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}