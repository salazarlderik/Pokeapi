import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pokemon_provider.dart';
import 'pokemon_screen.dart';

/// Muestra la lista de regiones de Pokémon.
/// Esta es ahora la pantalla de inicio de la app.
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
          _buildRegionTile(
            context,
            'Kanto (Gen 1)',
            1, 151,
            'kanto.PNG', 
          ),
          _buildRegionTile(
            context,
            'Johto (Gen 2)',
            152, 251,
            'jotho.png', 
          ),
          _buildRegionTile(
            context,
            'Hoenn (Gen 3)',
            252, 386,
            'hoenn.png',
          ),
          _buildRegionTile(
            context,
            'Sinnoh (Gen 4)',
            387, 493,
            'sinnoh.png',
          ),
          _buildRegionTile(
            context,
            'Unova (Gen 5)',
            494, 649,
            'unova.png', 
          ),
          _buildRegionTile(
            context,
            'Kalos (Gen 6)',
            650, 721,
            'kalos.PNG',
          ),
          _buildRegionTile(
            context,
            'Alola (Gen 7)',
            722, 809,
            'alola.png',
          ),
          _buildRegionTile(
            context,
            'Galar (Gen 8)',
            810, 898,
            'galar.PNG',
          ),
          
          _buildRegionTile(
            context,
            'Hisui (Legends)',
            899, 905,         
            'hisui.PNG',       
          ),
          _buildRegionTile(
            context,
            'Paldea (Gen 9)', 
            906, 1025,       
            'paldea.PNG',
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir cada 'botón' de región con fondo.
  Widget _buildRegionTile(BuildContext context, String name, int startId, int endId, String imageName) {
    final String imagePath = 'assets/images/$imageName';

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (context) => PokemonProvider(startId: startId, endId: endId),
                child: PokemonScreen(regionName: name),
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Ink.image(
              image: AssetImage(imagePath), // Usa la ruta completa
              height: 100,
              fit: BoxFit.cover,
              // ErrorBuilder por si no encuentra la imagen
              onImageError: (exception, stackTrace) {
                // Si hay un error, muestra un fondo de color simple
                print("Error loading image $imagePath: $exception");
              },
            ),

            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5))
                      ]
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}