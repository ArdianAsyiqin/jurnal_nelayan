import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/daftar_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JurnalNelayanApp());
}

class JurnalNelayanApp extends StatelessWidget {
  const JurnalNelayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jurnal Nelayan',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const DaftarScreen(),
    );
  }
}