import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/db_helper.dart';
import '../models/tangkapan.dart';
import 'pengaturan_service.dart';

/// Kesalahan dengan pesan yang siap ditampilkan ke pengguna.
class CloudException implements Exception {
  final String pesan;
  CloudException(this.pesan);

  @override
  String toString() => pesan;
}

class HasilPulihkan {
  final int ditambah;
  final int dilewati;

  const HasilPulihkan({required this.ditambah, required this.dilewati});
}

/// Cadangan dan pemulihan data ke Firestore.
///
/// Struktur di cloud:  cadangan / {kode kapal} / tangkapan / {id}
/// Kode kapal diambil dari nama kapal di Pengaturan.
class CloudService {
  static const _batasWaktu = Duration(seconds: 15);
  static const _ukuranBatch = 400; // batas Firestore 500 operasi per batch

  static const _pesanKoneksi =
      'Tidak bisa terhubung ke cloud. Periksa koneksi internet.';

  /// "KM Sinar Laut" -> "km_sinar_laut"
  static String _buatKode(String namaKapal) {
    return namaKapal
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static Future<CollectionReference<Map<String, dynamic>>> _koleksi() async {
    final p = await PengaturanService.baca();
    final kode = _buatKode(p.namaKapal);
    if (kode.isEmpty) {
      throw CloudException(
        'Isi nama kapal di Pengaturan dulu. '
            'Nama kapal dipakai sebagai kode cadangan.',
      );
    }
    return FirebaseFirestore.instance
        .collection('cadangan')
        .doc(kode)
        .collection('tangkapan');
  }

  static CloudException _terjemahkan(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return CloudException(_pesanKoneksi);
      case 'permission-denied':
        return CloudException(
          'Akses ditolak. Periksa aturan (rules) Firestore.',
        );
      default:
        return CloudException('Terjadi kesalahan cloud (${e.code}).');
    }
  }

  /// Penanda isi catatan, dipakai untuk mencegah data ganda saat pemulihan.
  static String _tanda(Tangkapan t) => [
    t.tanggal.toIso8601String(),
    t.jenisIkan.trim().toLowerCase(),
    t.beratKg,
    t.hargaPerKg ?? '',
    t.catatan.trim(),
  ].join('|');

  /// Apakah isi dokumen di cloud sama dengan data lokal.
  static bool _samaIsi(Map<String, dynamic> cloud, Map<String, Object?> lokal) {
    if (cloud.length != lokal.length) return false;
    for (final e in lokal.entries) {
      if (!cloud.containsKey(e.key)) return false;
      final x = cloud[e.key];
      final y = e.value;
      if (x is num && y is num) {
        if (x.toDouble() != y.toDouble()) return false;
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }


  /// Cadangan bersifat cermin: dokumen di cloud yang sudah tidak ada di HP
  /// ikut dihapus. Hanya dokumen yang berubah yang ditulis ulang.
  ///
  /// [otomatis] true berarti dipanggil oleh cadangan otomatis. Dalam mode ini
  /// data lokal yang kosong diperbolehkan (misalnya semua catatan dihapus),
  /// karena pemanggil sudah memastikan HP ini pernah sinkron sebelumnya.
  static Future<int> cadangkan({bool otomatis = false}) async {
    final koleksi = await _koleksi();
    final lokal = await DbHelper.instance.semua();

    // Pengaman: jangan sampai cadangan terhapus karena data lokal kosong.
    if (lokal.isEmpty && !otomatis) {
      throw CloudException(
        'Tidak ada data di HP untuk dicadangkan. '
            'Jika data hilang, gunakan Pulihkan.',
      );
    }

    try {
      // Baca dari server dulu. Kalau offline, gagal cepat sebelum menulis.
      final cloud = await koleksi
          .get(const GetOptions(source: Source.server))
          .timeout(_batasWaktu);

      final idLokal = lokal.map((e) => e.id.toString()).toSet();
      final dataCloud = {for (final d in cloud.docs) d.id: d.data()};
      final operasi = <void Function(WriteBatch)>[];

      for (final doc in cloud.docs) {
        if (!idLokal.contains(doc.id)) {
          operasi.add((b) => b.delete(doc.reference));
        }
      }
      for (final t in lokal) {
        final data = t.toMap()..remove('id');
        final lama = dataCloud[t.id.toString()];
        if (lama != null && _samaIsi(lama, data)) continue; // tidak berubah
        operasi.add((b) => b.set(koleksi.doc(t.id.toString()), data));
      }

      for (var i = 0; i < operasi.length; i += _ukuranBatch) {
        final batch = FirebaseFirestore.instance.batch();
        for (final op in operasi.skip(i).take(_ukuranBatch)) {
          op(batch);
        }
        await batch.commit().timeout(_batasWaktu);
      }

      await PengaturanService.simpanTerakhirCadangan(DateTime.now());
      return lokal.length;
    } on TimeoutException {
      throw CloudException(_pesanKoneksi);
    } on FirebaseException catch (e) {
      throw _terjemahkan(e);
    }
  }

  /// Mengambil data dari Firestore dan menambahkannya ke SQLite.
  /// Catatan yang isinya sudah ada di HP dilewati, jadi tidak ada data ganda.
  static Future<HasilPulihkan> pulihkan() async {
    final koleksi = await _koleksi();

    try {
      final snap = await koleksi
          .get(const GetOptions(source: Source.server))
          .timeout(_batasWaktu);

      if (snap.docs.isEmpty) {
        throw CloudException('Belum ada cadangan di cloud untuk kapal ini.');
      }

      final lokal = await DbHelper.instance.semua();
      final sudahAda = lokal.map(_tanda).toSet();

      final baru = <Tangkapan>[];
      var dilewati = 0;
      for (final doc in snap.docs) {
        final Tangkapan t;
        try {
          t = Tangkapan.fromMap(doc.data());
        } catch (_) {
          dilewati++;
          continue;
        }
        if (sudahAda.add(_tanda(t))) {
          baru.add(t);
        } else {
          dilewati++;
        }
      }

      await DbHelper.instance.tambahBanyak(baru);
      await PengaturanService.simpanTerakhirCadangan(DateTime.now());
      return HasilPulihkan(ditambah: baru.length, dilewati: dilewati);
    } on TimeoutException {
      throw CloudException(_pesanKoneksi);
    } on FirebaseException catch (e) {
      throw _terjemahkan(e);
    }
  }
}