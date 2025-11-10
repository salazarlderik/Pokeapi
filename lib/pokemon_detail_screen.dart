import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'utils/type_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  final Map<String, dynamic> species;

  const PokemonDetailScreen({
    Key? key,
    required this.pokemon,
    required this.species,
  }) : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoadingAbilities = true;
  bool _isLoadingTypeDefenses = true;
  bool _isLoadingVarietyTypes = true;
  bool _isLoadingEvolution = true;

  Map<String, String> _abilityDetails = {};
  Map<String, double> _typeEffectiveness = {};
  List<dynamic> _varieties = [];

  late Map<String, dynamic> _currentPokemonData;
  late String _currentVarietyName;
  late String _currentPokemonNameForEvo;
  
  late String _regionSuffixForEvo; 

  Map<String, String> _varietyFirstTypes = {};
  Map<String, dynamic>? _evolutionChainData;

  static const Map<String, String> _regionalEvolutionOverrides = {
    // ... (Tu mapa de overrides) ...
    'alola:rattata': 'Lvl 20 (Night)',
    'alola:sandshrew': 'Use Ice Stone',
    'alola:vulpix': 'Use Ice Stone',
    'alola:meowth': 'High Friendship',
    'alola:geodude': 'Lvl 25',
    'alola:graveler': 'Trade',
    'alola:grimer': 'Lvl 38',
    'alola:exeggcute': 'Use Leaf Stone',
    'alola:cubone': 'Lvl 28 (Night)',
    'galar:meowth': 'Lvl 28',
    'galar:ponyta': 'Lvl 40',
    'galar:farfetchd': '3 Critical Hits',
    'galar:corsola': 'Lvl 38',
    'galar:zigzagoon': 'Lvl 20',
    'galar:linoone': 'Lvl 35 (Night)',
    'galar:darumaka': 'Use Ice Stone',
    'galar:yamask': 'Take 49+ DMG, no faint',
    'galar:slowpoke>slowbro': 'Use Galarica Cuff',
    'galar:slowpoke>slowking': 'Use Galarica Wreath',
    'hisui:growlithe': 'Use Fire Stone',
    'hisui:voltorb': 'Use Leaf Stone',
    'hisui:qwilfish': 'Barb Barrage (Strong)',
    'hisui:sneasel': 'Use Razor Claw (Day)',
    'hisui:basculin': 'Recoil Damage',
    'hisui:scyther': 'Use Black Augurite',
    'hisui:petilil': 'Use Sun Stone',
    'hisui:goomy': 'Lvl 40 (Rain)',
    'hisui:rufflet': 'Lvl 54',
    'hisui:bergmite': 'Lvl 37',
    'hisui:stantler': 'Psyshield Bash (Agile)',
    'paldea:wooper': 'Lvl 20',
  };

  static const List<String> _alolanForms = ['rattata', 'raticate', 'raichu', 'sandshrew', 'sandslash', 'vulpix', 'ninetales', 'diglett', 'dugtrio', 'meowth', 'persian', 'geodude', 'graveler', 'golem', 'grimer', 'muk', 'exeggutor', 'marowak'];
  static const List<String> _galarianForms = ['meowth', 'ponyta', 'rapidash', 'slowpoke', 'slowbro', 'farfetchd', 'weezing', 'mr-mime', 'articuno', 'zapdos', 'moltres', 'slowking', 'corsola', 'zigzagoon', 'linoone', 'darumaka', 'darmanitan', 'yamask', 'stunfisk'];
  static const List<String> _hisuianForms = ['growlithe', 'arcanine', 'voltorb', 'electrode', 'typhlosion', 'samurott', 'decidueye', 'qwilfish', 'sneasel', 'lilligant', 'zorua', 'zoroark', 'braviary', 'sliggoo', 'goodra', 'avalugg', 'basculin'];
  static const List<String> _paldeanForms = ['wooper', 'tauros'];
  static const List<String> _galarianEvolutions = ['perrserker', 'mr-rime', 'cursola', 'obstagoon', 'sirfetchd', 'runerigus'];
  static const List<String> _hisuianEvolutions = ['wyrdeer', 'kleavor', 'ursaluna', 'basculegion', 'sneasler', 'overqwil'];
  static const List<String> _paldeanEvolutions = ['clodsire'];
  static const List<String> _hisuiPreEvos = ['rowlet', 'dartrix', 'cyndaquil', 'quilava', 'oshawott', 'dewott', 'petilil', 'rufflet', 'goomy', 'bergmite', 'zorua'];
  static const List<String> _hisuiLine = [..._hisuianForms, ..._hisuianEvolutions, ..._hisuiPreEvos];
  static const List<String> _paldeaLine = [..._paldeanForms, ..._paldeanEvolutions];
  static const List<String> _branchReplacements = ['meowth', 'sneasel', 'qwilfish', 'yamask', 'farfetchd', 'mr-mime', 'corsola', 'wooper', 'ponyta', 'darumaka', 'zigzagoon', 'linoone', 'pikachu', 'exeggcute', 'cubone'];
  final List<String> _allTypes = ['normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'];

  @override
  void initState() {
    super.initState();
    _currentPokemonData = widget.pokemon;
    _varieties = widget.species['varieties'] ?? [];
    _currentVarietyName = _currentPokemonData['name'];
    _currentPokemonNameForEvo = widget.pokemon['name'];
    _regionSuffixForEvo = _getRegionSuffix();
    _loadAllDataForCurrentForm();
    _fetchEvolutionChain();
  }

  String _getRegionSuffix() {
    String currentName = _currentPokemonNameForEvo;
    String speciesName = widget.species['name'];
    if (currentName.contains('-alola')) return '-alola';
    if (currentName.contains('-galar')) return '-galar';
    if (currentName.contains('-hisui')) return '-hisui';
    if (currentName.contains('-paldea')) return '-paldea';
    if (_galarianEvolutions.contains(speciesName)) return '-galar';
    if (_hisuianEvolutions.contains(speciesName)) return '-hisui';
    if (_paldeanEvolutions.contains(speciesName)) return '-paldea';
    return ""; 
  }

  Future<void> _loadAllDataForCurrentForm() async {
    setState(() { _isLoadingAbilities = true; _isLoadingTypeDefenses = true; _isLoadingVarietyTypes = true; });
    await Future.wait([ _fetchAbilityDetails(_currentPokemonData), _fetchTypeEffectiveness(_currentPokemonData), _fetchVarietyTypes(), ]);
  }

  Future<void> _fetchEvolutionChain() async {
    setState(() { _isLoadingEvolution = true; });
    String speciesNameForEvo = widget.species['name']; 
    if (speciesNameForEvo == 'slowpoke' && widget.pokemon['name'].contains('-galar')) { speciesNameForEvo = 'slowpoke'; }
    try {
      final speciesData = await _apiService.fetchPokemonSpecies(speciesNameForEvo);
      final evoChainUrl = speciesData['evolution_chain']['url'] as String;
      final data = await _apiService.fetchEvolutionChain(evoChainUrl);
      if (mounted) { setState(() { _evolutionChainData = data; _isLoadingEvolution = false; }); }
    } catch (e) {
      print('Error fetching evolution chain: $e');
      if (mounted) { setState(() { _isLoadingEvolution = false; }); }
    }
  }

  Future<void> _fetchVarietyTypes() async {
    Map<String, String> newVarietyFirstTypes = {};
    List<Future<void>> typeFetchFutures = [];
    for (var variety in _varieties) {
      final String formName = variety['pokemon']['name'];
      if (formName != widget.species['name'] && !_varietyFirstTypes.containsKey(formName)) {
        typeFetchFutures.add(() async {
          try {
            final pokemonDetails = await _apiService.fetchPokemonDetails(formName);
            final types = (pokemonDetails['types'] as List<dynamic>).map<String>((typeInfo) => typeInfo['type']['name'] as String).toList();
            if (types.isNotEmpty) { newVarietyFirstTypes[formName] = types.first; }
          } catch (e) { print('Error fetching types for variety $formName: $e'); }
        }());
      }
    }
    await Future.wait(typeFetchFutures);
    if (mounted) { setState(() { _varietyFirstTypes.addAll(newVarietyFirstTypes); _isLoadingVarietyTypes = false; }); }
  }

  Future<void> _fetchAbilityDetails(Map<String, dynamic> pokemonData) async {
    final abilities = (pokemonData['abilities'] as List<dynamic>);
    Map<String, String> newAbilityDetails = {};
    List<Future<Map<String, String?>>> futures = [];
    for (var abilityInfo in abilities) {
      final abilityUrl = abilityInfo['ability']['url'] as String;
      final abilityName = abilityInfo['ability']['name'] as String;
      futures.add(_fetchSingleAbility(abilityUrl, abilityName));
    }
    try {
      final results = await Future.wait(futures);
      for (var res in results) { newAbilityDetails[res['name']!] = res['effect'] ?? 'Description not available.'; }
    } catch (e) { print('Error fetching abilities: $e'); }
    if (mounted) { setState(() { _abilityDetails = newAbilityDetails; _isLoadingAbilities = false; }); }
  }

  Future<Map<String, String?>> _fetchSingleAbility(String url, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entry = (data['effect_entries'] as List<dynamic>).firstWhere((e) => e['language']['name'] == 'en', orElse: () => null);
        return {'name': name, 'effect': entry != null ? entry['short_effect'] : null};
      }
    } catch (e) { print('Error fetching $name: $e'); }
    return {'name': name, 'effect': 'Error loading.'};
  }

  Future<void> _fetchTypeEffectiveness(Map<String, dynamic> pokemonData) async {
    if (!mounted) return;
    Map<String, double> effectivenessMap = { for (var type in _allTypes) type: 1.0 };
    final types = (pokemonData['types'] as List<dynamic>).map<String>((typeInfo) => typeInfo['type']['name'] as String).toList();
    List<Future<http.Response>> typeFutures = [];
    for (var typeName in types) { typeFutures.add(http.get(Uri.parse('https://pokeapi.co/api/v2/type/$typeName'))); }
    try {
      final typeResponses = await Future.wait(typeFutures);
      for (var response in typeResponses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['damage_relations'];
          for (var type in data['double_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 2.0; }
          for (var type in data['half_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.5; }
          for (var type in data['no_damage_from']) { effectivenessMap[type['name']] = (effectivenessMap[type['name']] ?? 1.0) * 0.0; }
        }
      }
      if (mounted) { setState(() { _typeEffectiveness = effectivenessMap; _isLoadingTypeDefenses = false; }); }
    } catch (e) {
      print('Error fetching type defenses: $e');
      if (mounted) { setState(() { _isLoadingTypeDefenses = false; }); }
    }
  }

  Future<void> _onFormChanged(String? newFormName) async {
    if (newFormName == null || newFormName == _currentVarietyName) return;
    try {
      final newPokemonData = await _apiService.fetchPokemonDetails(newFormName);
      if (mounted) {
        setState(() {
          _currentPokemonData = newPokemonData;
          _currentVarietyName = newFormName;
          _currentPokemonNameForEvo = newFormName;
          _regionSuffixForEvo = _getRegionSuffix();
        });
        await Future.wait([ _loadAllDataForCurrentForm(), _fetchEvolutionChain(), ]);
      }
    } catch (e) { print('Error changing form: $e'); }
  }

  Future<void> _navigateToPokemon(String pokemonName) async {
    if (pokemonName == _currentPokemonNameForEvo) return;
    showDialog( context: context, barrierDismissible: false, builder: (context) => Center(child: CircularProgressIndicator()), );
    try {
      final species = await _apiService.fetchPokemonSpecies(pokemonName);
      final pokemon = await _apiService.fetchPokemonDetails(pokemonName);
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => PokemonDetailScreen( pokemon: pokemon, species: species, ), ), );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Could not load Pokémon: $pokemonName')), );
      print('Error navigating to $pokemonName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String heroId = widget.species['id'].toString();
    final String name = _currentPokemonData['name'];
    final sprites = _currentPokemonData['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork = otherSprites?['official-artwork'] as Map<String, dynamic>?;
    final String imageUrl = officialArtwork?['front_default'] as String? ?? sprites['front_default'] as String? ?? '';
    final types = (_currentPokemonData['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
    final abilityNames = (_currentPokemonData['abilities'] as List<dynamic>).map<String>((ability) => ability['ability']['name'] as String).toList();
    final int height = _currentPokemonData['height'];
    final int weight = _currentPokemonData['weight'];
    final stats = (_currentPokemonData['stats'] as List<dynamic>);
    final mainColor = types.isNotEmpty ? getTypeColor(types.first) : Colors.grey;
    return Scaffold(
      appBar: AppBar(title: Text(name[0].toUpperCase() + name.substring(1)), backgroundColor: mainColor),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.10)])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _isLoadingVarietyTypes ? Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) : _buildFormSelector(mainColor),
              Hero(
                tag: 'pokemon-$heroId',
                child: imageUrl.isEmpty ? Icon(Icons.image_not_supported, size: 200, color: Colors.grey) : Image.network( imageUrl, width: 250, height: 250, fit: BoxFit.contain, loadingBuilder: (c, ch, p) => p == null ? ch : Center(child: SizedBox(height: 250, child: CircularProgressIndicator())), errorBuilder: (c, e, s) => Icon(Icons.error, size: 200, color: Colors.red) )
              ),
              const SizedBox(height: 16),
              Text(name.toUpperCase(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 8.0, runSpacing: 4.0, children: types.map((type) => _buildTypeChip(type)).toList()),
              const SizedBox(height: 24),
              _buildStatsCard(heroId, weight, height),
              const SizedBox(height: 24),
              Text('Base Stats', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: stats.map((stat) => _buildStatBar(stat)).toList()))),
              const SizedBox(height: 24),
              Text('Evolution Chain', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildEvolutionSection(),
              const SizedBox(height: 24),
              Text('Type Defenses', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: _isLoadingTypeDefenses ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator())) : Table( border: TableBorder.all( color: Colors.grey.shade300, width: 1.0, ), children: [ _buildTypeRow(_allTypes.sublist(0, 9)), _buildTypeRow(_allTypes.sublist(9, 18)), ], ),
              ),
              const SizedBox(height: 24),
              Text('Abilities', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isLoadingAbilities ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: abilityNames.length,
                      itemBuilder: (context, index) {
                        final abilityName = abilityNames[index];
                        final description = _abilityDetails[abilityName] ?? 'Loading...';
                        return Card(
                          elevation: 2, margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(abilityName[0].toUpperCase() + abilityName.substring(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Text(description.replaceAll('\n', ' '), style: TextStyle(color: Colors.grey[700])),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTypeRow(List<String> types) {
    return TableRow(
      children: types.map((type) {
        final double multiplier = _typeEffectiveness[type] ?? 1.0;
        return _buildTypeEffectivenessItem(type, multiplier);
      }).toList(),
    );
  }

  Widget _buildFormSelector(Color mainColor) {
    if (_varieties.length <= 1) { return SizedBox.shrink(); }
    final Color gmaxColor = Colors.red[700]!;
    final Color primalColor = Colors.deepOrange[800]!;
    List<Widget> chips = _varieties.map((variety) {
      final String formName = variety['pokemon']['name'];
      final String formattedName = formName.replaceAll('-', ' ').replaceFirst(widget.species['name'], '').trim().split(' ').where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
      final String displayName = formattedName.isEmpty ? 'Base' : formattedName;
      final bool isSelected = formName == _currentVarietyName;
      Color chipBackgroundColor = Colors.white;
      Color chipBorderColor = Colors.grey.shade300;
      Color chipTextColor = Colors.black87;
      Widget? chipAvatar;
      Widget? finalChipWidget;

      if (displayName.contains('Mega')) {
        final keystoneGradient = LinearGradient( colors: [ Color(0xFF63D8FF), Color(0xFF8B55FF), Color(0xFFFFC75F), Color(0xFFFF5656) ], begin: Alignment.topLeft, end: Alignment.bottomRight, );
        finalChipWidget = Container(
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration( borderRadius: BorderRadius.circular(12), gradient: keystoneGradient, boxShadow: isSelected ? [ BoxShadow( color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 4), ), ] : null, ),
          padding: const EdgeInsets.all(2.0),
          child: Container( 
            decoration: BoxDecoration( color: isSelected ? Color(0xFF282828) : Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(10.0), ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar( radius: 12, backgroundColor: Colors.transparent, child: Image.asset('assets/images/piedra_activadora.png'), ),
                const SizedBox(width: 8),
                Text( displayName, style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, ), ),
              ],
            ),
          ),
        );
      } else {
        if (displayName.contains('Gmax')) {
          Color themeColor = gmaxColor;
          chipAvatar = CircleAvatar( radius: 12, backgroundColor: Colors.transparent, child: Image.asset('assets/images/gmax_logo.png'), );
          chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
          chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        } else if (displayName.contains('Alola') || displayName.contains('Galar') || displayName.contains('Hisui')) {
          final String? firstType = _varietyFirstTypes[formName];
          if (firstType != null) {
            final regionalTypeColor = getTypeColor(firstType);
            chipBackgroundColor = isSelected ? regionalTypeColor : regionalTypeColor.withOpacity(0.2);
            chipBorderColor = isSelected ? regionalTypeColor : regionalTypeColor.withOpacity(0.5);
            chipTextColor = isSelected ? Colors.white : regionalTypeColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
          } else {
            Color themeColor = Colors.teal[600]!;
            chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
            chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
            chipTextColor = isSelected ? Colors.white : Colors.black87;
          }
        } else if (displayName.contains('Primal')) {
          Color themeColor = primalColor;
          chipBackgroundColor = isSelected ? themeColor : themeColor.withOpacity(0.2);
          chipBorderColor = isSelected ? themeColor : themeColor.withOpacity(0.5);
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        } else if (displayName == 'Base') {
          Color themeColor = mainColor;
          chipBackgroundColor = isSelected ? themeColor : Colors.white;
          chipBorderColor = isSelected ? themeColor : Colors.grey.shade300;
          chipTextColor = isSelected ? Colors.white : Colors.black87;
        }
        finalChipWidget = Chip(
          avatar: chipAvatar,
          label: Text( displayName, style: TextStyle( color: chipTextColor, fontWeight: FontWeight.bold, shadows: isSelected && chipTextColor == Colors.white ? [ Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5), offset: Offset(1,1)) ] : null, ), ),
          backgroundColor: chipBackgroundColor,
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide( color: chipBorderColor, width: 2, ), ),
          elevation: isSelected ? 4 : 0,
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () => _onFormChanged(formName),
          child: finalChipWidget,
        ),
      );
    }).toList();
    bool needsScrolling = _varieties.length > 3;
    Widget chipRow = Row( mainAxisAlignment: needsScrolling ? MainAxisAlignment.start : MainAxisAlignment.center, children: chips, );
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: needsScrolling ? SingleChildScrollView( scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics(), child: chipRow, ) : Center( child: chipRow, ),
    );
  }

  Widget _buildStatsCard(String id, int weight, int height) {
    return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _buildStatColumn('ID', '#$id'), _buildStatColumn('Weight', '${weight / 10} kg'), _buildStatColumn('Height', '${height / 10} m'), ], ), ), );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column( children: [ Text(label.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), ], );
  }

  Widget _buildTypeChip(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Chip( backgroundColor: typeColor, label: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), avatar: SvgPicture.network(typeImageUrl, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)), );
  }

  String _formatStatName(String statName) {
    switch (statName) {
      case 'hp': return 'HP';
      case 'attack': return 'Attack';
      case 'defense': return 'Defense';
      case 'special-attack': return 'Sp. Atk';
      case 'special-defense': return 'Sp. Def';
      case 'speed': return 'Speed';
      default: return statName.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  Widget _buildStatBar(dynamic stat) {
    final String name = stat['stat']['name'];
    final int value = stat['base_stat'];
    Color barColor;
    if (value <= 59) { barColor = Colors.red; }
    else if (value <= 99) { barColor = Colors.yellow.shade700; }
    else if (value <= 159) { barColor = Colors.green; }
    else { barColor = Colors.blue; }
    final double normalizedValue = value > 200 ? 1.0 : (value / 200.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ SizedBox(width: 80, child: Text(_formatStatName(name), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)), Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), ], ),
          const SizedBox(height: 2),
          ClipRRect( borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: normalizedValue, backgroundColor: barColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(barColor), minHeight: 12), ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    final typeColor = getTypeColor(type);
    final typeImageUrl = 'https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg';
    return Container( width: 28, height: 28, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.all(2), child: SvgPicture.network(typeImageUrl, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), placeholderBuilder: (context) => SizedBox.shrink()), );
  }

  Widget _buildTypeEffectivenessItem(String type, double multiplier) {
    String multiplierText;
    Color multiplierColor;
    if (multiplier == 4.0) { multiplierText = 'x4'; multiplierColor = Colors.red.shade900; }
    else if (multiplier == 2.0) { multiplierText = 'x2'; multiplierColor = Colors.orange.shade700; }
    else if (multiplier == 0.5) { multiplierText = 'x½'; multiplierColor = Colors.lightGreen.shade600; }
    else if (multiplier == 0.25) { multiplierText = 'x¼'; multiplierColor = Colors.green.shade800; }
    else if (multiplier == 0.0) { multiplierText = 'x0'; multiplierColor = Colors.black87; }
    else { multiplierText = ''; multiplierColor = Colors.transparent; }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [ _buildTypeIcon(type), const SizedBox(height: 4), SizedBox( height: 16, child: Text( multiplierText, style: TextStyle(fontWeight: FontWeight.bold, color: multiplierColor, fontSize: 11), ), ) ],
      ),
    );
  }

  Widget _buildEvolutionSection() {
    if (_isLoadingEvolution) { return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator())) ); }
    if (_evolutionChainData == null || _evolutionChainData?['chain'] == null) { return SizedBox.shrink(); }
    Widget evolutionTree = _buildEvolutionBranch(_evolutionChainData!['chain'], _regionSuffixForEvo);
    final bool hasEvolutions = (_evolutionChainData!['chain']['evolves_to'] as List).isNotEmpty;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: hasEvolutions ? SingleChildScrollView( scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics(), child: evolutionTree, ) : Center( child: evolutionTree, ),
      ),
    );
  }

  List<dynamic> _filterEvolutions(List<dynamic> evolutions, String baseName, String regionSuffix) {
    if (regionSuffix == '-galar') {
      return evolutions.where((e) {
        String evoName = e['species']['name'];
        var details = e['evolution_details'];
        if (details.isEmpty) return false;
        String itemName = details.first['item']?['name'] ?? "";
        int? minLevel = details.first['min_level'];
        if (_galarianEvolutions.contains(evoName)) return true;
        if (itemName == 'galarica-cuff' || itemName == 'galarica-wreath') return true;
        if (_galarianForms.contains(evoName)) {
          if (evoName == 'slowbro' && minLevel == 37) return false;
          if (evoName == 'slowking' && itemName == 'kings-rock') return false;
          return true;
        }
        return false;
      }).toList();
    }
    if (regionSuffix == '-hisui') { return evolutions.where((e) => _hisuiLine.contains(e['species']['name'])).toList(); }
    if (regionSuffix == '-paldea') { return evolutions.where((e) => _paldeaLine.contains(e['species']['name'])).toList(); }
    return evolutions.where((e) {
      String evoName = e['species']['name'];
      if (_galarianEvolutions.contains(evoName)) return false;
      if (_hisuianEvolutions.contains(evoName)) return false;
      if (_paldeanEvolutions.contains(evoName)) return false;
      if (baseName == 'slowpoke') {
         var details = e['evolution_details'];
         if (details.isNotEmpty) {
           String itemName = details.first['item']?['name'] ?? "";
           if (itemName == 'galarica-cuff' || itemName == 'galarica-wreath') { return false; }
         }
      }
      return true;
    }).toList();
  }

  Widget _buildEvolutionBranch(Map<String, dynamic> chainLink, String regionSuffix) {
    if (chainLink.isEmpty) return SizedBox.shrink();
    String baseName = chainLink['species']['name'];
    String pokemonName = baseName;
    String suffixForThisNode = "";
    if (_galarianEvolutions.contains(baseName) || _hisuianEvolutions.contains(baseName) || _paldeanEvolutions.contains(baseName)) {
      pokemonName = baseName;
    }
    else if (_alolanForms.contains(baseName) && regionSuffix == "-alola") { suffixForThisNode = "-alola"; }
    else if (_galarianForms.contains(baseName) && regionSuffix == "-galar") { suffixForThisNode = "-galar"; }
    else if (_hisuianForms.contains(baseName) && regionSuffix == "-hisui") { suffixForThisNode = "-hisui"; }
    else if (_paldeanForms.contains(baseName) && regionSuffix == "-paldea") { suffixForThisNode = "-paldea"; }
    String currentBaseName = widget.species['name'];
    if (regionSuffix.isEmpty && (currentBaseName == 'pikachu' || currentBaseName == 'exeggcute' || currentBaseName == 'cubone')) {
      if (baseName == 'raichu' || baseName == 'exeggutor' || baseName == 'marowak') { suffixForThisNode = "-alola"; }
    }
    if ((baseName == 'slowbro' || baseName == 'slowking') && (_currentPokemonNameForEvo == 'slowpoke-galar' || regionSuffix == '-galar')) {
      var details = chainLink['evolution_details'];
      if (details.isNotEmpty) {
        String itemName = details.first['item']?['name'] ?? "";
        if (itemName == 'galarica-cuff' || itemName == 'galarica-wreath') { suffixForThisNode = '-galar'; }
      }
    }
    if (pokemonName == baseName) { pokemonName = "$baseName$suffixForThisNode"; }
    if (pokemonName == 'darmanitan-galar') { pokemonName = 'darmanitan-galar-standard'; }
    bool isCurrent = _currentPokemonNameForEvo == pokemonName;
    Widget currentPokemonWidget = _buildEvolutionNode(pokemonName, isCurrent);
    List<dynamic> evolutions = chainLink['evolves_to'] ?? [];
    List<dynamic> filteredEvolutions = _filterEvolutions(evolutions, baseName, regionSuffix);
    if (filteredEvolutions.isEmpty) { return currentPokemonWidget; }
    List<Widget> evolutionWidgets = [];
    for (var evoLink in filteredEvolutions) {
      String evolutionDetails = _formatEvolutionDetails( evoLink['evolution_details'], baseName, evoLink['species']['name'], regionSuffix );
      Widget nextPokemonWidget = _buildEvolutionBranch(evoLink, regionSuffix);
      evolutionWidgets.add( _buildEvolutionArrowRow(evolutionDetails, nextPokemonWidget) );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [ currentPokemonWidget, const SizedBox(width: 8), Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: evolutionWidgets, ), ],
    );
  }

  Widget _buildEvolutionArrowRow(String evolutionDetails, Widget nextPokemonWidget) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_rounded, color: Colors.grey[600]),
              if (evolutionDetails.isNotEmpty)
                SizedBox( width: 90, child: Text( evolutionDetails, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]), textAlign: TextAlign.center, ), ),
            ],
          ),
        ),
        nextPokemonWidget,
      ],
    );
  }

  String _formatEvolutionDetails(List<dynamic> detailsList, String fromPokemonName, String toPokemonName, String regionSuffix) {
    String region = regionSuffix.replaceAll('-', '');
    String complexKey = "$region:$fromPokemonName>$toPokemonName";
    if (_regionalEvolutionOverrides.containsKey(complexKey)) { return _regionalEvolutionOverrides[complexKey]!; }
    String simpleKey = "$region:$fromPokemonName";
    if (_regionalEvolutionOverrides.containsKey(simpleKey)) { return _regionalEvolutionOverrides[simpleKey]!; }
    if (region.isEmpty) {
      if (_hisuianEvolutions.contains(toPokemonName)) {
        String hisuiKey = "hisui:$fromPokemonName";
        if (_regionalEvolutionOverrides.containsKey(hisuiKey)) { return _regionalEvolutionOverrides[hisuiKey]!; }
      }
      if (_galarianEvolutions.contains(toPokemonName)) {
        String galarKey = "galar:$fromPokemonName";
        if (_regionalEvolutionOverrides.containsKey(galarKey)) { return _regionalEvolutionOverrides[galarKey]!; }
      }
    }
    if (toPokemonName.startsWith('lycanroc') && detailsList.isNotEmpty) {
      var details = detailsList.first;
      String timeOfDay = details['time_of_day'] ?? "";
      String trigger = details['trigger']?['name'] ?? "";
      if (timeOfDay == 'night') return "Lvl 25 (Night)";
      if (trigger == 'other') return "Lvl 25 (Own Tempo)";
      return "Lvl 25 (Day)";
    }
    if (detailsList.isEmpty) return "";
    dynamic details = detailsList.first;
    if (region.isNotEmpty) {
      final regionalDetail = detailsList.firstWhere( (d) => d['location']?['name'] == region, orElse: () => detailsList.first, );
      details = regionalDetail;
    }
    String trigger = details['trigger']['name'].replaceAll('-', ' ');
    String item = details['item']?['name']?.replaceAll('-', ' ') ?? "";
    String minLevel = details['min_level']?.toString() ?? "";
    String minHappiness = details['min_happiness']?.toString() ?? "";
    String timeOfDay = details['time_of_day'] ?? "";
    String knownMove = details['known_move']?['name']?.replaceAll('-', ' ') ?? "";
    String knownMoveType = details['known_move_type']?['name'] ?? "";
    String location = details['location']?['name']?.replaceAll('-', ' ') ?? "";
    String formattedDetails = "";
    if (minLevel.isNotEmpty) formattedDetails += "Lvl $minLevel";
    else if (item.isNotEmpty) formattedDetails += "Use ${item[0].toUpperCase() + item.substring(1)}";
    else if (trigger == "trade") formattedDetails += "Trade";
    else if (minHappiness.isNotEmpty) formattedDetails += "High Friendship";
    else if (knownMove.isNotEmpty) formattedDetails += "Knows $knownMove";
    else if (knownMoveType.isNotEmpty) formattedDetails += "Knows $knownMoveType move";
    else if (location.isNotEmpty) formattedDetails += "in $location";
    else if (trigger == "other" || trigger == "recoil damage") formattedDetails = "Special method";
    else formattedDetails += trigger[0].toUpperCase() + trigger.substring(1);
    if (timeOfDay.isNotEmpty && !formattedDetails.contains(timeOfDay)) { formattedDetails += "\n($timeOfDay)"; }
    return formattedDetails;
  }

  // ==========================================================
  // 👇 ¡NODO DE EVOLUCIÓN REVERTIDO A SU ESTADO ORIGINAL!
  //    Ahora funcionará con el api_service.dart corregido.
  // ==========================================================
  Widget _buildEvolutionNode(String pokemonName, bool isCurrent) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.fetchDefaultPokemonDetailsFromSpecies(pokemonName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(width: 110, height: 110, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (snapshot.hasError) {
          // Lógica de reintento original (para Darmanitan, etc.)
          if(pokemonName.contains('-') && !pokemonName.endsWith('-standard')) {
            String baseName = pokemonName.split('-').first;
            bool isCurrentBase = _currentPokemonNameForEvo.split('-').first == baseName;
            return _buildEvolutionNode(baseName, isCurrentBase);
          }
          if(pokemonName == 'darmanitan-galar-standard') {
            return _buildEvolutionNode('darmanitan-galar', isCurrent);
          }
          
          return Container(width: 110, height: 110, child: Icon(Icons.error_outline, color: Colors.red));
        }

        if (!snapshot.hasData) return SizedBox.shrink();

        final pokemonData = snapshot.data!;
        final spriteUrl = pokemonData['sprites']?['front_default'] ?? '';
        final types = (pokemonData['types'] as List<dynamic>).map<String>((type) => type['type']['name'] as String).toList();
        final mainColor = types.isNotEmpty ? getTypeColor(types.first) : Colors.grey;

        final String actualPokemonName = pokemonData['name'];
        // Usamos el 'pokemonName' que nos pasaron para el 'isCurrent'
        // Esto es porque 'actualPokemonName' podría ser 'midday' por defecto
        // si algo saliera mal, pero 'pokemonName' es el que *queremos*
        // que sea (ej. 'lycanroc-midnight')
        final bool isCurrentFinal = _currentPokemonNameForEvo == pokemonName || _currentPokemonNameForEvo == actualPokemonName;

        return GestureDetector(
          onTap: () {
            if (isCurrentFinal) return;
            _navigateToPokemon(actualPokemonName);
          },
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isCurrentFinal ? mainColor.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentFinal ? Border.all(color: mainColor, width: 2) : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                if (spriteUrl.isNotEmpty)
                  Image.network(spriteUrl, width: 80, height: 80, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                SizedBox(height: 4),
                Text(
                  actualPokemonName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}