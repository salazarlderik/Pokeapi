import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_screen.dart';

/// Muestra la lista de regiones de Pokémon.
class RegionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Region'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Pasa el ID de la generación (número)
          _buildRegionTile(context, 'Kanto (Gen 1)', 1, 'kanto.PNG'),
          _buildRegionTile(context, 'Johto (Gen 2)', 2, 'jotho.png'),
          _buildRegionTile(context, 'Hoenn (Gen 3)', 3, 'hoenn.png'),
          _buildRegionTile(context, 'Sinnoh (Gen 4)', 4, 'sinnoh.png'),
          _buildRegionTile(context, 'Unova (Gen 5)', 5, 'unova.png'),
          _buildRegionTile(context, 'Kalos (Gen 6)', 6, 'kalos.PNG'),
          _buildRegionTile(context, 'Alola (Gen 7)', 7, 'alola.png'),
          // Gen 8 (Galar + Hisui)
          _buildRegionTile(context, 'Galar & Hisui (Gen 8)', 8, 'galar.PNG'),
          _buildRegionTile(context, 'Paldea (Gen 9)', 9, 'paldea.PNG'),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir cada 'botón' de región.
  Widget _buildRegionTile(BuildContext context, String displayName, int generationId, String imageName) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Al tocar, crea el Provider pasándole el ID de la generación.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (context) => PokemonProvider(generationId: generationId),
                child: PokemonScreen(regionName: displayName),
              ),
            ),
          );
        },
        child: Stack(
          // ... (El Stack con la imagen de fondo y el gradiente no cambia) ...
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
                    displayName,
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