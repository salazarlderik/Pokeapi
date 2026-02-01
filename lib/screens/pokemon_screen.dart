import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/pokemon_provider.dart';
import '../widgets/pokemon_list_card.dart';
import '../utils/pokemon_constants.dart';
import '../utils/pokemon_extensions.dart';

/// Pantalla que muestra la cuadrícula de Pokémon de una región específica.
/// Maneja la búsqueda, el filtrado por tipos y la visualización responsiva.
class PokemonScreen extends StatefulWidget {
  final String regionNameKey;
  const PokemonScreen({super.key, required this.regionNameKey});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  // Controladores para el input de búsqueda y el scroll de la grilla.
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider sin escuchar cambios (listen: false) para evitar
    // que todo el Scaffold se redibuje innecesariamente; solo el Consumer lo hará.
    Provider.of<PokemonProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regionNameKey).tr(),
        actions: [
          // Botón para alternar idioma (EN/ES)
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => context.setLocale(
              context.locale == const Locale('en') ? const Locale('es') : const Locale('en')
            ),
          ),
        ],
      ),
      // Usamos Consumer para reconstruir SOLO el cuerpo cuando cambian los filtros o datos.
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
              // Barra de búsqueda y botón de filtro
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(child: _buildSearchBar(provider)),
                    const SizedBox(width: 8),
                    _buildTypeMenu(provider),
                  ],
                ),
              ),
              // Área principal: Lista vacía o Grid de Pokémon
              Expanded(
                child: provider.filteredPokemon.isEmpty
                    ? Center(child: Text('no_pokemon_found'.tr()))
                    : _buildGrid(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(PokemonProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => provider.updateSearch(val), // Actualiza el filtro en tiempo real
      decoration: InputDecoration(
        hintText: "Search",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: BorderSide(color: Colors.grey.shade300)
        ),
      ),
    );
  }

  /// Construye el menú desplegable para filtrar por tipo elemental.
  Widget _buildTypeMenu(PokemonProvider provider) {
    return PopupMenuButton<String?>(
      initialValue: provider.selectedType,
      onSelected: (String? type) {
        if (type == null) {
          // --- LÓGICA DE RESET TOTAL ---
          // Al seleccionar "All Types", limpiamos los filtros en el provider
          provider.resetToDefault(); 
          
          // Recargamos la pantalla completa para asegurar que el estado visual (scroll, focus)
          // se limpie perfectamente y volver al estado inicial.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonScreen(regionNameKey: widget.regionNameKey),
            ),
          );
        } else {
          // Aplicamos filtro por tipo y volvemos al inicio de la lista
          provider.updateType(type);
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: provider.selectedType == null 
              ? Colors.grey.shade200 
              : provider.selectedType!.toTypeColor.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.filter_alt, 
          color: provider.selectedType == null ? Colors.black54 : provider.selectedType!.toTypeColor
        ),
      ),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String?>(
          value: null, 
          child: Text("All Types", style: TextStyle(fontWeight: FontWeight.bold))
        ),
        const PopupMenuDivider(),
        // Generamos dinámicamente las opciones de tipos con sus iconos SVG
        ...PokeConstants.allTypes.map((type) => PopupMenuItem<String>(
          value: type,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: type.toTypeColor, borderRadius: BorderRadius.circular(4)),
                child: SvgPicture.network(
                  'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg', 
                  width: 14, height: 14, 
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                ),
              ),
              const SizedBox(width: 12),
              Text('types.$type'.tr().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, PokemonProvider provider) {
    final pokemonList = provider.filteredPokemon;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Cálculo responsivo: Determina columnas según el ancho del dispositivo
    int crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 800 ? 4 : screenWidth > 500 ? 3 : 2;

    return GridView.builder(
      controller: _scrollController,
      // ValueKey fuerza a reconstruir el Grid si cambian los filtros para evitar errores de renderizado
      key: ValueKey('grid_${provider.selectedType}_${provider.searchQuery}'),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        return PokemonListCard(
          key: ValueKey(pokemonList[index]['name']),
          pokemonSpecies: pokemonList[index], 
          // Pasamos el sufijo (ej: '-hisui') a la tarjeta para que cargue la imagen/tipos correctos
          suffix: provider.currentRegionSuffix, 
        );
      },
    );
  }
}