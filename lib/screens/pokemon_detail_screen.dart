import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

import '../services/api_service.dart';
import '../utils/pokemon_constants.dart';
import '../utils/pokemon_extensions.dart';
import '../widgets/evolution_chain_widget.dart';

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
    if (mounted) setState(() { _isLoadingAbilities = false; });
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
        // --- APPBAR ESTILO TECH/ROTOM ---
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador LED Azul decorativo
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.7), 
                    blurRadius: 6, 
                    spreadRadius: 2
                  )
                ],
              ),
            ),
            const SizedBox(width: 15),
            Text(
              name.toString().capitalize,
              style: const TextStyle(
                fontWeight: FontWeight.bold, // Negrita
                fontSize: 22, // Tamaño 22
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white), 
            onPressed: () => context.setLocale(
              context.locale == const Locale('en') ? const Locale('es') : const Locale('en')
            )
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [mainColor.withValues(alpha: 0.3), Theme.of(context).scaffoldBackgroundColor],
          ),
        ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    label: Text('types.$type'.tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    avatar: SvgPicture.network('https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg', width: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
  );

  Widget _buildFormSelector(Color mainColor) {
    if (_varieties.length <= 1) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: _varieties.map((v) {
              final fName = v['pokemon']['name'] as String;
              final isSel = fName == _currentVarietyName;
              final display = fName.replaceFirst(widget.species['name'], '').cleanName;
              final label = display.isEmpty ? 'forms.base'.tr() : display;
              if (label.contains('Mega')) return _buildMegaChip(label, fName, isSel);
              final typeColor = _varietyFirstTypes[fName]?.toTypeColor ?? mainColor;
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(showCheckmark: false, avatar: label.contains('Gmax') ? Image.asset('assets/images/gmax_logo.png', width: 20, color: isSel ? Colors.white : null) : null, label: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), selected: isSel, onSelected: (_) => _onFormChanged(fName), selectedColor: label.contains('Gmax') ? Colors.red[700] : typeColor));
            }).toList())),
      ),
    );
  }

  Widget _buildMegaChip(String label, String fName, bool isSel) {
    return GestureDetector(onTap: () => _onFormChanged(fName), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF63D8FF), Color(0xFF8B55FF), Color(0xFFFFC75F)]), border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2), boxShadow: isSel ? [const BoxShadow(blurRadius: 4, offset: Offset(0, 2))] : null), child: Row(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/images/piedra_activadora.png', width: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));
  }

  Widget _buildEvolutionSection() {
    if (_isLoadingEvolution) return const Center(child: CircularProgressIndicator());
    if (_evolutionChainData == null) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: ConstrainedBox(constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64), child: Center(child: EvolutionChainWidget(chain: _evolutionChainData!['chain'], regionSuffix: _regionSuffixForEvo, currentPokemonName: _currentPokemonNameForEvo))))));
  }

  Widget _buildStatsCard(String id, int weight, int height) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statCol('stats.weight'.tr(), '${weight / 10} kg', Icons.fitness_center),
            _vDivider(),
            _statCol('stats.id'.tr(), '#${id.padLeft(3, '0')}', Icons.tag),
            _vDivider(),
            _statCol('stats.height'.tr(), '${height / 10} m', Icons.height),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.grey[300]);

  Widget _statCol(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[500], size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatBar(dynamic stat) {
    final int val = stat['base_stat'];
    final color = val <= 59 ? Colors.red : val <= 99 ? Colors.yellow.shade700 : val <= 159 ? Colors.green : Colors.blue;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_translateStat(stat['stat']['name']).tr(), style: const TextStyle(fontWeight: FontWeight.bold)), Text(val.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: val / 200, backgroundColor: color.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(color), minHeight: 12)),
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
    Color multColor = mult == 4.0 ? Colors.red.shade900 : mult == 2.0 ? Colors.orange : mult == 0.5 ? Colors.lightGreen : mult == 0.25 ? Colors.green.shade900 : Colors.black;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: type.toTypeColor, borderRadius: BorderRadius.circular(4)), child: SvgPicture.network('https://raw.githubusercontent.com/duiker101/pokemon-type-svg-icons/master/icons/$type.svg', width: 22, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))), const SizedBox(height: 4), Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: multColor))]));
  }

  Widget _buildAbilitiesList(List abs) => Column(children: abs.map((a) => Card(child: ListTile(title: Text(a['ability']['name'].toString().cleanName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_abilityDetails[a['ability']['name']] ?? '')))).toList());

  void _onFormChanged(String name) async {
    final data = await _apiService.fetchPokemonDetails(name);
    setState(() { 
      _currentPokemonData = data; 
      _currentVarietyName = name; 
      _currentPokemonNameForEvo = name; 
      _regionSuffixForEvo = _getRegionSuffix(); 
    });
    _loadAllDataForCurrentForm(); 
    _fetchEvolutionChain();
  }
}