import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/pokemon_cache.dart';
import 'screens/region_screen.dart'; 

// Variable global para acceder a la base de datos desde cualquier servicio (ApiService).
late Isar isar;

void main() async {
  // Asegura que el motor de Flutter esté listo antes de ejecutar código asíncrono (BD, Archivos).
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // --- INICIALIZACIÓN DE ISAR (Base de Datos Local) ---
  // 1. Obtenemos una ruta segura en el sistema de archivos del celular para guardar los datos.
  final dir = await getApplicationDocumentsDirectory();
  
  // 2. Abrimos la instancia de la base de datos pasando el esquema de nuestra caché.
  isar = await Isar.open(
    [PokemonCacheSchema], // Esquema generado automáticamente para guardar JSONs.
    directory: dir.path,
  );

  runApp(
    // Envolvemos la app en EasyLocalization para inyectar el soporte multi-idioma desde el inicio.
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations', // Carpeta donde están los JSONs de texto.
      fallbackLocale: const Locale('en'), // Si falla el idioma del sistema, usa inglés.
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
      // Conectamos los delegados de localización para que los widgets sepan cómo traducirse.
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale, // Idioma actual seleccionado.
      title: 'Pokédex Isar',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: RegionScreen(), // Pantalla inicial (Menú de Regiones).
    );
  }
}