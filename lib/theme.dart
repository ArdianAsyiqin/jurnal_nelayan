import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palet warna aplikasi (laut: biru tua, teal, dan oranye sebagai aksi).
class Warna {
  static const navy = Color(0xFF0E2A3B);
  static const navyKartu = Color(0xFF17405A);
  static const teal = Color(0xFF1F7A8C);
  static const tealMuda = Color(0xFFCFE3E8);
  static const tealSangatMuda = Color(0xFFE6F0F3);
  static const oranye = Color(0xFFC2511F);
  static const latar = Color(0xFFF4F7F8);
  static const garis = Color(0xFFDDE6EA);
  static const garisInput = Color(0xFFC5D3D9);
  static const teks = Color(0xFF1B2B34);
  static const teksRedup = Color(0xFF4F6672);
  static const teksTerang = Color(0xFFA9C4CE);
}

/// Gaya tombol aksi utama (oranye), dipakai untuk "Tambah" dan "Simpan".
ButtonStyle gayaAksi() => FilledButton.styleFrom(
      backgroundColor: Warna.oranye,
      foregroundColor: Colors.white,
    );

OutlineInputBorder _garisInput(Color warna, [double lebar = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: warna, width: lebar),
    );

ThemeData buildTheme() {
  final skema = ColorScheme.fromSeed(
    seedColor: Warna.teal,
    primary: Warna.teal,
    secondary: Warna.oranye,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.latar,
    appBarTheme: const AppBarTheme(
      backgroundColor: Warna.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: _garisInput(Warna.garisInput),
      enabledBorder: _garisInput(Warna.garisInput),
      focusedBorder: _garisInput(Warna.teal, 2),
      errorBorder: _garisInput(Colors.red.shade700),
      focusedErrorBorder: _garisInput(Colors.red.shade700, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.teal,
        side: const BorderSide(color: Warna.teal, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
