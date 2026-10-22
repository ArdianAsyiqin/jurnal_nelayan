import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tangkapan.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_bawah.dart';
import '../widgets/foto_tangkapan.dart';
import 'form_screen.dart';

/// Layar detail. Mengubah atau menghapus langsung ke database, lalu kembali
/// ke layar daftar dengan nilai `true` agar daftar dimuat ulang.
class DetailScreen extends StatelessWidget {
  final Tangkapan item;

  const DetailScreen({super.key, required this.item});

  Future<void> _ubah(BuildContext context) async {
    final hasil = await Navigator.push<Tangkapan>(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(awal: item)),
    );
    if (hasil == null) return;
    await DbHelper.instance.ubah(hasil);
    if (context.mounted) Navigator.pop(context, true);
  }

  Future<void> _hapus(BuildContext context) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text(
          'Catatan ${item.jenisIkan} tanggal ${formatTanggal(item.tanggal)} '
          'akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Warna.oranye)),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    await DbHelper.instance.hapus(item.id!);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final pendapatan = item.estimasiPendapatan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tangkapan'),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _hapus(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          FotoTangkapan(
            path: item.pathFoto,
            lebar: double.infinity,
            tinggi: 220,
            ukuranIkon: 72,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jenisIkan,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Warna.teks,
                  ),
                ),
                const SizedBox(height: 4),
                _Baris(label: 'Tanggal', nilai: formatTanggal(item.tanggal)),
                _Baris(label: 'Berat', nilai: formatBerat(item.beratKg)),
                _Baris(
                  label: 'Harga per kg',
                  nilai: item.hargaPerKg == null
                      ? '-'
                      : formatRupiah(item.hargaPerKg!),
                ),
                _Baris(
                  label: 'Estimasi pendapatan',
                  nilai: pendapatan == null ? '-' : formatRupiah(pendapatan),
                ),
                _Baris(
                  label: 'Lokasi',
                  nilai: item.punyaLokasi
                      ? formatKoordinat(item.latitude!, item.longitude!)
                      : '-',
                ),
                _Baris(
                  label: 'Catatan',
                  nilai: item.catatan.isEmpty ? '-' : item.catatan,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BarBawah(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => _ubah(context),
                  child: const Text('Ubah'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Warna.oranye,
                    side: const BorderSide(color: Warna.oranye, width: 1.5),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _hapus(context),
                  child: const Text('Hapus'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final String label;
  final String nilai;

  const _Baris({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Warna.garis)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Warna.teksRedup),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Warna.teks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
