import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tangkapan.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_bawah.dart';
import '../widgets/foto_tangkapan.dart';
import 'detail_screen.dart';
import 'form_screen.dart';

class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key});

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  // Data dibaca dari SQLite, bukan lagi dari memori.
  List<Tangkapan> _data = [];
  bool _memuat = true;

  double get _totalBerat =>
      _data.fold(0.0, (jumlah, e) => jumlah + e.beratKg);

  double get _totalPendapatan =>
      _data.fold(0.0, (jumlah, e) => jumlah + (e.estimasiPendapatan ?? 0));

  @override
  void initState() {
    super.initState();
    _muat();
  }

  /// Membaca ulang seluruh catatan dari database.
  Future<void> _muat() async {
    final hasil = await DbHelper.instance.semua();
    if (!mounted) return;
    setState(() {
      _data = hasil;
      _memuat = false;
    });
  }

  void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _tambah() async {
    final hasil = await Navigator.push<Tangkapan>(
      context,
      MaterialPageRoute(builder: (_) => const FormScreen()),
    );
    if (hasil == null) return;
    await DbHelper.instance.tambah(hasil);
    if (!mounted) return;
    await _muat();
    if (!mounted) return;
    _info('Catatan tersimpan');
  }

  Future<void> _buka(Tangkapan item) async {
    // Layar detail mengubah/menghapus langsung ke database,
    // lalu mengembalikan true bila ada perubahan.
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
    if (berubah != true || !mounted) return;
    await _muat();
    if (!mounted) return;
    _info('Perubahan tersimpan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(
            totalBerat: _totalBerat,
            totalPendapatan: _totalPendapatan,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Catatan Terbaru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Warna.teks,
                ),
              ),
            ),
          ),
          Expanded(
            child: _memuat
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? const _KosongView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    itemCount: _data.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _KartuTangkapan(
                      item: _data[i],
                      onTap: () => _buka(_data[i]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BarBawah(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: gayaAksi(),
                onPressed: _tambah,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Tangkapan'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // TODO: hubungkan ke Firebase Firestore (cadangkan).
                      onPressed: () => _info(
                          'Cadangan cloud akan dihubungkan pada tahap Firebase'),
                      child: const Text(
                        'Cadangkan ke Cloud',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // TODO: hubungkan ke Firebase Firestore (pulihkan).
                      onPressed: () => _info(
                          'Pemulihan cloud akan dihubungkan pada tahap Firebase'),
                      child: const Text(
                        'Pulihkan dari Cloud',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double totalBerat;
  final double totalPendapatan;

  const _Header({required this.totalBerat, required this.totalPendapatan});

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: Warna.navy,
      padding: EdgeInsets.fromLTRB(20, atas + 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logbook Tangkapan',
            style: TextStyle(fontSize: 13, color: Warna.teksTerang),
          ),
          const SizedBox(height: 4),
          // Nama contoh. Tahap berikutnya: ambil dari SharedPreferences.
          const Text(
            'KM Sinar Laut',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Text(
            'Pak Rahman',
            style: TextStyle(fontSize: 14, color: Warna.teksTerang),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Statistik(
                  label: 'Total tangkapan',
                  nilai: formatBerat(totalBerat),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Statistik(
                  label: 'Estimasi pendapatan',
                  nilai: formatRupiah(totalPendapatan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Statistik extends StatelessWidget {
  final String label;
  final String nilai;

  const _Statistik({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.navyKartu,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Warna.teksTerang),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuTangkapan extends StatelessWidget {
  final Tangkapan item;
  final VoidCallback onTap;

  const _KartuTangkapan({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Warna.garis),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FotoTangkapan(
                path: item.pathFoto,
                lebar: 56,
                tinggi: 56,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.jenisIkan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Warna.teks,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTanggal(item.tanggal),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Warna.teksRedup,
                      ),
                    ),
                    if (item.punyaLokasi)
                      Text(
                        formatKoordinatSingkat(
                            item.latitude!, item.longitude!),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Warna.teksRedup,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatBerat(item.beratKg),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Warna.teks,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KosongView extends StatelessWidget {
  const _KosongView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.set_meal, size: 56, color: Warna.teal),
            SizedBox(height: 12),
            Text(
              'Belum ada catatan tangkapan.\nKetuk "Tambah Tangkapan" untuk memulai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Warna.teksRedup),
            ),
          ],
        ),
      ),
    );
  }
}
