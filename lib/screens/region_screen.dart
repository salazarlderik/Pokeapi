import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pokemon_provider.dart';
import 'pokemon_screen.dart';
import 'package:easy_localization/easy_localization.dart';

/// Pantalla principal (Menú) que muestra todas las regiones disponibles.
/// Actúa como punto de entrada para cargar datos de generaciones específicas.
class RegionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title_header').tr(),
        actions: [
          // Lógica simple para alternar entre inglés y español usando EasyLocalization
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
          // Generaciones estándar (1 a 7)
          _buildRegionTile(context, 'regions.kanto', 1, 'kanto.PNG'),
          _buildRegionTile(context, 'regions.johto', 2, 'jotho.png'),
          _buildRegionTile(context, 'regions.hoenn', 3, 'hoenn.png'),
          _buildRegionTile(context, 'regions.sinnoh', 4, 'sinnoh.png'),
          _buildRegionTile(context, 'regions.unova', 5, 'unova.png'),
          _buildRegionTile(context, 'regions.kalos', 6, 'kalos.PNG'),
          _buildRegionTile(context, 'regions.alola', 7, 'alola.png'),
          
          // Caso Especial Gen 8: La API agrupa Galar y Hisui en la misma generación (8).
          // Usamos 'regionFilter' para decirle al Provider qué rango de IDs cargar.
          _buildRegionTile(context, 'regions.galar', 8, 'galar.PNG', regionFilter: 'galar'),
          _buildRegionTile(context, 'regions.hisui', 8, 'hisui.png', regionFilter: 'hisui'),
          
          // Generación 9
          _buildRegionTile(context, 'regions.paldea', 9, 'paldea.PNG'),
        ],
      ),
    );
  }

  /// Construye la tarjeta visual y maneja la navegación a la lista de Pokémon.
  Widget _buildRegionTile(
    BuildContext context, 
    String displayKey, 
    int generationId, 
    String imageName, 
    {String? regionFilter} // Opcional: Solo necesario para dividir Gen 8
  ) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: () {
          // --- LÓGICA CLAVE DE NAVEGACIÓN ---
          // Aquí inyectamos el PokemonProvider ANTES de navegar a la pantalla de lista.
          // Esto garantiza que PokemonScreen reciba un provider fresco cargado solo con
          // los datos de la generación seleccionada.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (context) => PokemonProvider(
                  generationId: generationId,
                  regionFilter: regionFilter,
                ),
                child: PokemonScreen(regionNameKey: displayKey),
              ),
            ),
          );
        },
        // Diseño visual: Imagen de fondo con degradado para que el texto resalte
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Ink.image(
              image: AssetImage('assets/images/$imageName'),
              height: 100,
              fit: BoxFit.cover,
              onImageError: (exception, stackTrace) {
                print("Error loading image $imageName: $exception");
              },
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayKey.tr(), // Traducción del nombre de la región
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