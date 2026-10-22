import 'package:flutter/material.dart';

import 'screens/daftar_screen.dart';
import 'theme.dart';

void main() => runApp(const JurnalNelayanApp());

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
