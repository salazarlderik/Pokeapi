import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/pokemon_cache.dart';
import 'screens/region_screen.dart'; // Asegúrate de que apunte a tu pantalla inicial

// Variable global para usar Isar en toda la app
late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // --- INICIALIZACIÓN DE ISAR ---
  // Buscamos una carpeta segura en el sistema para la base de datos
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [PokemonCacheSchema],
    directory: dir.path,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Pokédex Isar',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: RegionScreen(),
    );
  }
}