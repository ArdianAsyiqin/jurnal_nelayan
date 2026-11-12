import 'package:shared_preferences/shared_preferences.dart';

/// Data pengaturan pengguna (nama nelayan dan nama kapal).
class Pengaturan {
  final String namaNelayan;
  final String namaKapal;

  const Pengaturan({required this.namaNelayan, required this.namaKapal});

  static const kosong = Pengaturan(namaNelayan: '', namaKapal: '');
}

/// Membaca dan menyimpan pengaturan lewat SharedPreferences.
class PengaturanService {
  static const _kunciNelayan = 'nama_nelayan';
  static const _kunciKapal = 'nama_kapal';
  static const _kunciOtomatis = 'cadangan_otomatis';
  static const _kunciTerakhir = 'cadangan_terakhir';
  static const _kunciTertunda = 'cadangan_tertunda';

  static Future<Pengaturan> baca() async {
    final p = await SharedPreferences.getInstance();
    return Pengaturan(
      namaNelayan: p.getString(_kunciNelayan) ?? '',
      namaKapal: p.getString(_kunciKapal) ?? '',
    );
  }

  static Future<void> simpan(Pengaturan data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kunciNelayan, data.namaNelayan);
    await p.setString(_kunciKapal, data.namaKapal);
  }

  /// Apakah cadangan otomatis dinyalakan.
  static Future<bool> bacaOtomatis() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kunciOtomatis) ?? false;
  }

  static Future<void> simpanOtomatis(bool nilai) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kunciOtomatis, nilai);
  }

  /// Waktu terakhir HP ini berhasil cadangkan atau pulihkan. Null = belum pernah.
  static Future<DateTime?> bacaTerakhirCadangan() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_kunciTerakhir);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> simpanTerakhirCadangan(DateTime waktu) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kunciTerakhir, waktu.millisecondsSinceEpoch);
  }


  static Future<bool> bacaTertunda() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kunciTertunda) ?? false;
  }

  static Future<void> simpanTertunda(bool nilai) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kunciTertunda, nilai);
  }
}