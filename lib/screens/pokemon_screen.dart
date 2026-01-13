import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/pokemon_provider.dart';
import '../widgets/pokemon_list_card.dart';
import '../utils/pokemon_constants.dart';
import '../utils/pokemon_extensions.dart';

class PokemonScreen extends StatefulWidget {
  final String regionNameKey;
  const PokemonScreen({super.key, required this.regionNameKey});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
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
    // Usamos listen: false aquí para que el build principal no se confunda
    final provider = Provider.of<PokemonProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regionNameKey).tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => context.setLocale(
              context.locale == const Locale('en') ? const Locale('es') : const Locale('en')
            ),
          ),
        ],
      ),
      body: Consumer<PokemonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
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
      onChanged: (val) => provider.updateSearch(val),
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

  Widget _buildTypeMenu(PokemonProvider provider) {
    return PopupMenuButton<String?>(
      initialValue: provider.selectedType,
      onSelected: (String? type) {
        if (type == null) {
          // --- EFECTO FLECHA DE REGRESO (REINICIO TOTAL) ---
          provider.resetToDefault(); 
          
          // Sustituimos la pantalla por una nueva idéntica pero limpia
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonScreen(regionNameKey: widget.regionNameKey),
            ),
          );
        } else {
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
    int crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 800 ? 4 : screenWidth > 500 ? 3 : 2;

    return GridView.builder(
      controller: _scrollController,
      // La Key asegura que Flutter no intente reciclar la Grid vieja
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
        );
      },
    );
  }
}