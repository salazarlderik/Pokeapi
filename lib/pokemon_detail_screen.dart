import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

import 'api_service.dart';
import 'pokemon_constants.dart';
import 'pokemon_extensions.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  final Map<String, dynamic> species;

  const PokemonDetailScreen({super.key, required this.pokemon, required this.species});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoadingAbilities = true;
  bool _isLoadingTypeDefenses = true;
  bool _isLoadingVarietyTypes = true;
  bool _isLoadingEvolution = true;

  final Map<String, String> _abilityDetails = {};
  Map<String, double> _typeEffectiveness = {};
  List<dynamic> _varieties = [];
  late Map<String, dynamic> _currentPokemonData;
  late String _currentVarietyName;
  late String _currentPokemonNameForEvo;
  late String _regionSuffixForEvo;
  final Map<String, String> _varietyFirstTypes = {};
  Map<String, dynamic>? _evolutionChainData;
  Locale? _previousLocale;

  @override
  void initState() {
    super.initState();
    _currentPokemonData = widget.pokemon;
    _varieties = widget.species['varieties'] ?? [];
    _currentVarietyName = _currentPokemonData['name'];
    _currentPokemonNameForEvo = widget.pokemon['name'];
    _regionSuffixForEvo = _getRegionSuffix();
    _fetchEvolutionChain();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.locale != _previousLocale) {
      _previousLocale = context.locale;
      _loadAllDataForCurrentForm();
    }
  }

  String _getRegionSuffix() {
    final String name = _currentPokemonNameForEvo;
    final String species = widget.species['name'];
    if (name.contains('-alola')) return '-alola';
    if (name.contains('-galar')) return '-galar';
    if (name.contains('-hisui')) return '-hisui';
    if (name.contains('-paldea') || name.startsWith('dudunsparce')) return '-paldea';
    if (PokeConstants.galarianEvolutions.contains(species)) return '-galar';
    if (PokeConstants.hisuianEvolutions.contains(species)) return '-hisui';
    if (PokeConstants.paldeanEvolutions.contains(species)) return '-paldea';
    return "";
  }

  Future<void> _loadAllDataForCurrentForm() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAbilities = true;
      _isLoadingTypeDefenses = true;
      _isLoadingVarietyTypes = true;
    });
    await Future.wait([
      _fetchAbilityDetails(_currentPokemonData, context.locale.languageCode),
      _fetchTypeEffectiveness(_currentPokemonData),
      _fetchVarietyTypes(),
    ]);
  }

  Future<void> _fetchEvolutionChain() async {
    setState(() => _isLoadingEvolution = true);
    String speciesEvo = widget.species['name'];
    if (speciesEvo == 'ursaluna') speciesEvo = 'teddiursa';
    if (speciesEvo.startsWith('dudunsparce')) speciesEvo = 'dunsparce';

    try {
      final speciesData = await _apiService.fetchPokemonSpecies(speciesEvo);
      final data = await _apiService.fetchEvolutionChain(speciesData['evolution_chain']['url']);
      if (mounted) setState(() { _evolutionChainData = data; _isLoadingEvolution = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingEvolution = false);
    }
  }

  Future<void> _fetchVarietyTypes() async {
    for (var v in _varieties) {
      final String fName = v['pokemon']['name'];
      if (!_varietyFirstTypes.containsKey(fName)) {
        try {
          final d = await _apiService.fetchPokemonDetails(fName);
          final t = (d['types'] as List).map((i) => i['type']['name'] as String).toList();
          if (t.isNotEmpty) _varietyFirstTypes[fName] = t.first;
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _isLoadingVarietyTypes = false);
  }

  Future<void> _fetchAbilityDetails(Map<String, dynamic> data, String lang) async {
    final abilities = data['abilities'] as List;
    for (var a in abilities) {
      final res = await _fetchSingleAbility(a['ability']['url'], a['ability']['name'], lang);
      _abilityDetails[res['name']!] = res['effect'] ?? 'abilities_fallback.no_desc'.tr();
    }
    if (mounted) setState(() => _isLoadingAbilities = false);
  }

  Future<Map<String, String?>> _fetchSingleAbility(String url, String name, String lang) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: {'cb': DateTime.now().millisecondsSinceEpoch.toString()});
      final res = await http.get(uri, headers: {'Accept-Language': lang});
      if (res.statusCode == 200) {
        final entries = jsonDecode(res.body)['flavor_text_entries'] as List;
        var entry = entries.firstWhere((e) => e['language']['name'] == lang, orElse: () => entries.firstWhere((e) => e['language']['name'] == 'en', orElse: () => null));
        return {'name': name, 'effect': entry?['flavor_text']?.replaceAll('\n', ' ')};
      }
    } catch (_) {}
    return {'name': name, 'effect': 'abilities_fallback.error'.tr()};
  }

  Future<void> _fetchTypeEffectiveness(Map<String, dynamic> data) async {
    Map<String, double> map = { for (var t in PokeConstants.allTypes) t: 1.0 };
    final types = (data['types'] as List).map((t) => t['type']['name'] as String).toList();
    try {
      final resps = await Future.wait(types.map((t) => http.get(Uri.parse('https://pokeapi.co/api/v2/type/$t'))));
      for (var r in resps) {
        if (r.statusCode == 200) {
          final dr = jsonDecode(r.body)['damage_relations'];
          for (var t in dr['double_damage_from']) { map[t['name']] = (map[t['name']] ?? 1.0) * 2.0; }
          for (var t in dr['half_damage_from']) { map[t['name']] = (map[t['name']] ?? 1.0) * 0.5; }
          for (var t in dr['no_damage_from']) { map[t['name']] = 0.0; }
        }
      }
      if (mounted) setState(() { _typeEffectiveness = map; _isLoadingTypeDefenses = false; });
    } catch (_) { if (mounted) setState(() => _isLoadingTypeDefenses = false); }
  }

  @override
  Widget build(BuildContext context) {
    final types = (_currentPokemonData['types'] as List).map((t) => t['type']['name'] as String).toList();
    final mainColor = types.first.toTypeColor;
    final name = _currentPokemonData['name'];
    final sprites = _currentPokemonData['sprites'];
    final imageUrl = sprites['other']?['official-artwork']?['front_default'] ?? sprites['front_default'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name.toString().capitalize),
        backgroundColor: mainColor,
        actions: [IconButton(icon: const Icon(Icons.language), onPressed: () => context.setLocale(context.locale == const Locale('en') ? const Locale('es') : const Locale('en')))],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [mainColor.withOpacity(0.25), mainColor.withOpacity(0.1)])),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _isLoadingVarietyTypes ? const Center(child: CircularProgressIndicator()) : _buildFormSelector(mainColor),
              Hero(tag: 'pokemon-${widget.species['id']}', child: imageUrl.isEmpty ? const Icon(Icons.image_not_supported, size: 200) : Image.network(imageUrl, height: 250, fit: BoxFit.contain)),
              const SizedBox(height: 16),
              Text(name.toString().toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Wrap(alignment: WrapAlignment.center, spacing: 8, children: types.map((t) => _buildTypeChip(t)).toList()),
              const SizedBox(height: 24),
              _buildStatsCard(widget.species['id'].toString(), _currentPokemonData['weight'], _currentPokemonData['height']),
              const SizedBox(height: 24),
              _sectionTitle('headers.base_stats'),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: (_currentPokemonData['stats'] as List).map((s) => _buildStatBar(s)).toList()))),
              const SizedBox(height: 24),
              _sectionTitle('headers.evolution_chain'),
              _buildEvolutionSection(),
              const SizedBox(height: 24),
              _sectionTitle('headers.type_defenses'),
              _buildTypeDefensesTable(),
              const SizedBox(height: 24),
              _sectionTitle('headers.abilities'),
              _isLoadingAbilities ? const Center(child: CircularProgressIndicator()) : _buildAbilitiesList(_currentPokemonData['abilities']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String key) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(key.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));

  Widget _buildTypeChip(String type) => Chip(
    backgroundColor: type.toTypeColor,
    label: Text('types.$type'.tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    avatar: SvgPicture.network('https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg', width: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
  );

  // Selector de formas CENTRADO
  Widget _buildFormSelector(Color mainColor) {
    if (_varieties.length <= 1) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center( // El Center asegura que el contenido pequeño se quede al medio
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos dentro del Row
            children: _varieties.map((v) {
              final fName = v['pokemon']['name'] as String;
              final isSel = fName == _currentVarietyName;
              final display = fName.replaceFirst(widget.species['name'], '').cleanName;
              final label = display.isEmpty ? 'forms.base'.tr() : display;

              if (label.contains('Mega')) return _buildMegaChip(label, fName, isSel);
              
              final typeColor = _varietyFirstTypes[fName]?.toTypeColor ?? mainColor;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  showCheckmark: false, // Sin paloma
                  avatar: label.contains('Gmax') 
                    ? Image.asset('assets/images/gmax_logo.png', width: 20, color: isSel ? Colors.white : null) 
                    : null,
                  label: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  selected: isSel, onSelected: (_) => _onFormChanged(fName),
                  selectedColor: label.contains('Gmax') ? Colors.red[700] : typeColor,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMegaChip(String label, String fName, bool isSel) {
    return GestureDetector(
      onTap: () => _onFormChanged(fName),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFF63D8FF), Color(0xFF8B55FF), Color(0xFFFFC75F)]),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2), // Marco delgado
          boxShadow: isSel ? [const BoxShadow(blurRadius: 4, offset: Offset(0, 2))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/piedra_activadora.png', width: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildEvolutionSection() {
    if (_isLoadingEvolution) return const Center(child: CircularProgressIndicator());
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16),
        child: _buildEvolutionBranch(_evolutionChainData!['chain'], _regionSuffixForEvo),
      ),
    );
  }

  Widget _buildEvolutionBranch(Map<String, dynamic> link, String suffix) {
    String base = link['species']['name'];
    String pName = _getEvoNodeName(base, suffix, link['evolution_details']);
    Widget node = _buildEvolutionNode(pName);

    List evos = link['evolves_to'] ?? [];
    List filtered = _filterEvolutions(evos, base, suffix);
    if (filtered.isEmpty) return node;

    return Row(children: [
      node,
      Column(children: filtered.map((e) => Row(children: [
        _evoArrow(_formatEvoDetails(e['evolution_details'], base, e['species']['name'], suffix)),
        _buildEvolutionBranch(e, suffix),
      ])).toList()),
    ]);
  }

  Widget _evoArrow(String text) => Container(width: 100, padding: const EdgeInsets.all(8), child: Column(children: [const Icon(Icons.arrow_forward), Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]));

  String _getEvoNodeName(String base, String suffix, List details) {
    if (base == 'dudunsparce') return 'dudunsparce-two-segment';
    if (PokeConstants.galarianEvolutions.contains(base) || PokeConstants.hisuianEvolutions.contains(base) || PokeConstants.paldeanEvolutions.contains(base)) return base;
    if (suffix == '-alola' && PokeConstants.alolanForms.contains(base)) return '$base$suffix';
    if (suffix == '-galar' && PokeConstants.galarianForms.contains(base)) return '$base$suffix';
    if (suffix == '-hisui' && PokeConstants.hisuianForms.contains(base)) return '$base$suffix';
    return base;
  }

  List _filterEvolutions(List evos, String base, String suffix) {
    return evos.where((e) {
      String name = e['species']['name'];
      if (suffix == '-galar') return PokeConstants.galarianEvolutions.contains(name) || PokeConstants.galarianForms.contains(name);
      if (suffix == '-hisui') return PokeConstants.hisuiLine.contains(name);
      if (suffix == '-paldea') return PokeConstants.paldeaLine.contains(name);
      return !PokeConstants.galarianEvolutions.contains(name);
    }).toList();
  }

  String _formatEvoDetails(List details, String from, String to, String suffix) {
    if (details.isEmpty) return "";
    final d = details.first;
    if (to.startsWith('lycanroc')) return d['time_of_day'] == 'night' ? 'evolutions.override_lycanroc_night'.tr() : 'evolutions.override_lycanroc_day'.tr();
    if (d['min_level'] != null) return 'evolutions.lvl'.tr(namedArgs: {'level': d['min_level'].toString()});
    if (d['item'] != null) return 'evolutions.use_item'.tr(namedArgs: {'item': d['item']['name'].toString().cleanName});
    return d['trigger']['name'].toString().cleanName;
  }

  Widget _buildEvolutionNode(String name) => FutureBuilder<Map<String, dynamic>>(
    future: name.contains('-') ? _apiService.fetchPokemonDetails(name) : _apiService.fetchDefaultPokemonDetailsFromSpecies(name),
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox(width: 80, height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      final data = snap.data!;
      final color = (data['types'] as List).first['type']['name'].toString().toTypeColor;
      final isCur = _currentPokemonNameForEvo == data['name'];
      return GestureDetector(
        onTap: isCur ? null : () => _navigateToPokemon(data['name']),
        child: Container(
          width: 100, padding: const EdgeInsets.all(8), margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: isCur ? color.withOpacity(0.1) : null, border: Border.all(color: isCur ? color : Colors.grey.shade300, width: 2), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Image.network(data['sprites']['front_default'] ?? '', height: 70), Text(data['name'].toString().cleanName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
        ),
      );
    },
  );

  Widget _buildStatBar(dynamic stat) {
    final int val = stat['base_stat'];
    final color = val <= 59 ? Colors.red : val <= 99 ? Colors.yellow.shade700 : val <= 159 ? Colors.green : Colors.blue;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_translateStat(stat['stat']['name']).tr(), style: const TextStyle(fontWeight: FontWeight.bold)), 
        Text(val.toString(), style: const TextStyle(fontWeight: FontWeight.bold))
      ]),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: val / 200, backgroundColor: color.withOpacity(0.2), valueColor: AlwaysStoppedAnimation(color), minHeight: 12)),
      const SizedBox(height: 8),
    ]);
  }

  String _translateStat(String s) => s == 'special-attack' ? 'stats.sp_atk' : s == 'special-defense' ? 'stats.sp_def' : 'stats.$s';

  Widget _buildTypeDefensesTable() {
    if (_isLoadingTypeDefenses) return const Center(child: CircularProgressIndicator());
    return Card(child: Table(border: TableBorder.all(color: Colors.grey.shade300), children: [_typeRow(PokeConstants.allTypes.sublist(0, 9)), _typeRow(PokeConstants.allTypes.sublist(9, 18))]));
  }

  TableRow _typeRow(List<String> types) => TableRow(children: types.map((t) => _typeEffectItem(t, _typeEffectiveness[t] ?? 1.0)).toList());

  Widget _typeEffectItem(String type, double mult) {
    String text = mult == 0.5 ? 'x½' : mult == 0.25 ? 'x¼' : mult == 0 ? 'x0' : mult == 1 ? '' : 'x${mult.toInt()}';
    
    Color multColor = Colors.black;
    if (mult == 4.0) multColor = Colors.red.shade900; // x4 Rojo Oscuro
    else if (mult == 2.0) multColor = Colors.orange;
    else if (mult == 0.5) multColor = Colors.lightGreen;
    else if (mult == 0.25) multColor = Colors.green.shade900; // x1/4 Verde Oscuro
    
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [
      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: type.toTypeColor, borderRadius: BorderRadius.circular(4)), child: SvgPicture.network('https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg', width: 22, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
      const SizedBox(height: 4), 
      Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: multColor)),
    ]));
  }

  Widget _buildAbilitiesList(List abs) => Column(children: abs.map((a) => Card(child: ListTile(title: Text(a['ability']['name'].toString().cleanName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_abilityDetails[a['ability']['name']] ?? '')))).toList());

  Widget _buildStatsCard(String id, int w, int h) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCol('stats.id'.tr(), '#$id'),
          _statCol('stats.weight'.tr(), '${w / 10} kg'),
          _statCol('stats.height'.tr(), '${h / 10} m')
        ]
      )
    )
  );

  Widget _statCol(String l, String v) => Column(children: [
    Text(l.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)), // Label Bold
    Text(v, style: const TextStyle(fontWeight: FontWeight.bold))
  ]);

  void _onFormChanged(String name) async {
    final data = await _apiService.fetchPokemonDetails(name);
    setState(() { _currentPokemonData = data; _currentVarietyName = name; _currentPokemonNameForEvo = name; _regionSuffixForEvo = _getRegionSuffix(); });
    _loadAllDataForCurrentForm(); _fetchEvolutionChain();
  }

  void _navigateToPokemon(String name) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    final s = await _apiService.fetchPokemonSpecies(name);
    final p = await _apiService.fetchPokemonDetails(name);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PokemonDetailScreen(pokemon: p, species: s)));
  }
}