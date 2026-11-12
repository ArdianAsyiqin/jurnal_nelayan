import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tangkapan.dart';
import '../theme.dart';
import '../utils/cloud_service.dart';
import '../utils/format.dart';
import '../utils/pengaturan_service.dart';
import '../widgets/bar_bawah.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'pengaturan_screen.dart';

class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key});

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  List<Tangkapan> _data = [];
  Pengaturan _pengaturan = Pengaturan.kosong;
  bool _memuat = true;

  // Proses cloud manual (cadangkan / pulihkan).
  bool _sibuk = false;
  String _pesanSibuk = '';

  // Cadangan otomatis.
  bool _otomatis = false;
  bool _tertunda = false;
  bool _otomatisBerjalan = false;
  DateTime? _terakhirSinkron;

  // Pencarian dan filter.
  final _kataCari = TextEditingController();
  DateTime? _tanggalFilter;

  // Total di header selalu dihitung dari semua data.
  double get _totalBerat =>
      _data.fold(0.0, (jumlah, e) => jumlah + e.beratKg);

  double get _totalPendapatan =>
      _data.fold(0.0, (jumlah, e) => jumlah + (e.estimasiPendapatan ?? 0));

  bool get _sedangFilter =>
      _kataCari.text.trim().isNotEmpty || _tanggalFilter != null;

  /// True bila ada proses cloud yang sedang berjalan (manual atau otomatis).
  bool get _cloudSibuk => _sibuk || _otomatisBerjalan;


  List<Tangkapan> get _tampil {
    final kata = _kataCari.text.trim().toLowerCase();
    return _data.where((e) {
      final cocokJenis =
          kata.isEmpty || e.jenisIkan.toLowerCase().contains(kata);
      final cocokTanggal =
          _tanggalFilter == null || _sama(e.tanggal, _tanggalFilter!);
      return cocokJenis && cocokTanggal;
    }).toList();
  }

  bool _sama(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _teksStatus {
    if (_sibuk) return _pesanSibuk;
    if (_otomatisBerjalan) return 'Mengirim cadangan otomatis...';
    final waktu =
    _terakhirSinkron == null ? null : formatWaktu(_terakhirSinkron!);
    if (!_otomatis) {
      return waktu == null
          ? 'Belum pernah dicadangkan ke cloud'
          : 'Terakhir sinkron: $waktu';
    }
    if (waktu == null) {
      return 'Cadangan otomatis aktif setelah kamu menekan '
          '"Cadangkan ke Cloud" sekali';
    }
    if (_tertunda) return 'Cadangan otomatis tertunda, menunggu koneksi';
    return 'Cadangan otomatis aktif • Terakhir sinkron: $waktu';
  }

  IconData get _ikonStatus {
    if (_cloudSibuk) return Icons.cloud_upload_outlined;
    if (_otomatis && _tertunda) return Icons.cloud_off_outlined;
    return Icons.cloud_done_outlined;
  }

  @override
  void initState() {
    super.initState();
    _mulai();
  }

  @override
  void dispose() {
    _kataCari.dispose();
    super.dispose();
  }

  Future<void> _mulai() async {
    await _muat();
    if (!mounted) return;
    // Kirim perubahan yang tertunda dari sesi sebelumnya (misalnya saat offline).
    _cadangOtomatis(hanyaJikaTertunda: true);
  }

  /// Membaca ulang catatan dari database dan pengaturan dari SharedPreferences.
  Future<void> _muat() async {
    try {
      final hasil = await DbHelper.instance.semua();
      final pengaturan = await PengaturanService.baca();
      if (!mounted) return;
      setState(() {
        _data = hasil;
        _pengaturan = pengaturan;
        _memuat = false;
      });
      await _muatStatusCloud();
    } catch (_) {
      if (!mounted) return;
      setState(() => _memuat = false);
      _info('Gagal membaca data. Coba buka ulang aplikasi.');
    }
  }

  Future<void> _muatStatusCloud() async {
    final otomatis = await PengaturanService.bacaOtomatis();
    final terakhir = await PengaturanService.bacaTerakhirCadangan();
    final tertunda = await PengaturanService.bacaTertunda();
    if (!mounted) return;
    setState(() {
      _otomatis = otomatis;
      _terakhirSinkron = terakhir;
      _tertunda = tertunda;
    });
  }

  void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Cadangan otomatis di latar belakang (tanpa dialog konfirmasi).
  ///
  /// Hanya berjalan bila: opsi dinyalakan, dan HP ini pernah cadangkan atau
  /// pulihkan sebelumnya (supaya HP baru yang masih kosong tidak menimpa
  /// cadangan lama di cloud).
  Future<void> _cadangOtomatis({bool hanyaJikaTertunda = false}) async {
    if (!await PengaturanService.bacaOtomatis()) return;
    if (await PengaturanService.bacaTerakhirCadangan() == null) return;
    if (hanyaJikaTertunda && !await PengaturanService.bacaTertunda()) return;

    // Tandai ada perubahan yang perlu dikirim. Kalau proses lain sedang
    // berjalan, perubahan ini diambil oleh putaran berikutnya.
    await PengaturanService.simpanTertunda(true);
    if (_otomatisBerjalan || _sibuk) return;
    if (!mounted) return;

    setState(() => _otomatisBerjalan = true);
    String? gagal;
    try {
      while (await PengaturanService.bacaTertunda()) {
        await PengaturanService.simpanTertunda(false);
        await CloudService.cadangkan(otomatis: true);
      }
    } on CloudException catch (e) {
      gagal = e.pesan;
      await PengaturanService.simpanTertunda(true);
    } catch (_) {
      gagal = 'Terjadi kesalahan.';
      await PengaturanService.simpanTertunda(true);
    }

    _otomatisBerjalan = false;
    if (!mounted) return;
    await _muatStatusCloud();
    if (!mounted) return;
    if (gagal != null) _info('Cadangan otomatis tertunda: $gagal');
  }

  Future<void> _tambah() async {
    final hasil = await Navigator.push<Tangkapan>(
      context,
      MaterialPageRoute(builder: (_) => const FormScreen()),
    );
    if (hasil == null) return;
    try {
      await DbHelper.instance.tambah(hasil);
    } catch (_) {
      if (!mounted) return;
      _info('Gagal menyimpan catatan. Coba lagi.');
      return;
    }
    if (!mounted) return;
    await _muat();
    if (!mounted) return;
    _info('Catatan tersimpan');
    _cadangOtomatis();
  }

  Future<void> _buka(Tangkapan item) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
    if (!mounted) return;
    await _muat(); // selalu muat ulang, bacanya murah
    if (!mounted) return;
    if (berubah == true) {
      _info('Perubahan tersimpan');
      _cadangOtomatis();
    }
  }

  Future<void> _bukaPengaturan() async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PengaturanScreen()),
    );
    if (berubah != true || !mounted) return;
    final pengaturan = await PengaturanService.baca();
    if (!mounted) return;
    setState(() => _pengaturan = pengaturan);
    await _muatStatusCloud();
    if (!mounted) return;
    _info('Pengaturan tersimpan');
    _cadangOtomatis(); // berlaku bila opsi baru dinyalakan
  }

  Future<bool> _konfirmasi(String judul, String isi, String tombol) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tombol),
          ),
        ],
      ),
    );
    return ya == true;
  }

  Future<void> _cadangkan() async {
    final lanjut = await _konfirmasi(
      'Cadangkan ke cloud?',
      'Semua catatan di HP ini akan dikirim ke cloud. Cadangan lama untuk '
          'kapal yang sama akan diganti dengan data di HP ini.',
      'Cadangkan',
    );
    if (!lanjut || !mounted) return;

    setState(() {
      _sibuk = true;
      _pesanSibuk = 'Mengirim data ke cloud...';
    });
    try {
      final jumlah = await CloudService.cadangkan();
      await PengaturanService.simpanTertunda(false);
      if (!mounted) return;
      await _muatStatusCloud();
      if (!mounted) return;
      _info('$jumlah catatan berhasil dicadangkan');
    } on CloudException catch (e) {
      if (!mounted) return;
      _info(e.pesan);
    } catch (_) {
      if (!mounted) return;
      _info('Pencadangan gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _pulihkan() async {
    final lanjut = await _konfirmasi(
      'Pulihkan dari cloud?',
      'Catatan dari cloud akan ditambahkan ke HP ini. Catatan yang sudah '
          'ada tidak akan digandakan.',
      'Pulihkan',
    );
    if (!lanjut || !mounted) return;

    setState(() {
      _sibuk = true;
      _pesanSibuk = 'Mengambil data dari cloud...';
    });
    try {
      final hasil = await CloudService.pulihkan();
      if (!mounted) return;
      await _muat();
      if (!mounted) return;
      _info(
        hasil.ditambah == 0
            ? 'Semua catatan sudah ada di HP ini'
            : '${hasil.ditambah} catatan dipulihkan'
            '${hasil.dilewati > 0 ? ' (${hasil.dilewati} sudah ada)' : ''}',
      );
    } on CloudException catch (e) {
      if (!mounted) return;
      _info(e.pesan);
    } catch (_) {
      if (!mounted) return;
      _info('Pemulihan gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _pilihTanggalFilter() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggalFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (dipilih != null) setState(() => _tanggalFilter = dipilih);
  }

  void _hapusFilter() {
    _kataCari.clear();
    setState(() => _tanggalFilter = null);
  }

  @override
  Widget build(BuildContext context) {
    final tampil = _tampil;

    return Scaffold(
      body: Column(
        children: [
          _Header(
            pengaturan: _pengaturan,
            totalBerat: _totalBerat,
            totalPendapatan: _totalPendapatan,
            onPengaturan: _bukaPengaturan,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kataCari,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari jenis ikan',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _kataCari.text.isEmpty
                          ? null
                          : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _kataCari.clear();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter tanggal',
                  onPressed: _pilihTanggalFilter,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
            ),
          ),
          if (_sedangFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (_tanggalFilter != null)
                    InputChip(
                      label: Text(formatTanggal(_tanggalFilter!)),
                      onDeleted: () => setState(() => _tanggalFilter = null),
                    ),
                  const Spacer(),
                  Text(
                    '${tampil.length} dari ${_data.length} catatan',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Warna.teksRedup,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
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
                ? const _KosongView(
              icon: Icons.set_meal,
              pesan:
              'Belum ada catatan tangkapan.\nKetuk "Tambah Tangkapan" untuk memulai.',
            )
                : tampil.isEmpty
                ? _KosongView(
              icon: Icons.search_off,
              pesan: 'Tidak ada catatan yang cocok.',
              aksi: TextButton(
                onPressed: _hapusFilter,
                child: const Text('Hapus filter'),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: tampil.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 10),
              itemBuilder: (context, i) => _KartuTangkapan(
                item: tampil[i],
                onTap: () => _buka(tampil[i]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BarBawah(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cloudSibuk)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(_ikonStatus, size: 16, color: Warna.teksRedup),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _teksStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Warna.teksRedup,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: gayaAksi(),
                onPressed: _sibuk ? null : _tambah,
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
                      onPressed: _cloudSibuk ? null : _cadangkan,
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
                      onPressed: _cloudSibuk ? null : _pulihkan,
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
  final Pengaturan pengaturan;
  final double totalBerat;
  final double totalPendapatan;
  final VoidCallback onPengaturan;

  const _Header({
    required this.pengaturan,
    required this.totalBerat,
    required this.totalPendapatan,
    required this.onPengaturan,
  });

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    final kapalKosong = pengaturan.namaKapal.isEmpty;
    final nelayanKosong = pengaturan.namaNelayan.isEmpty;

    return Container(
      width: double.infinity,
      color: Warna.navy,
      padding: EdgeInsets.fromLTRB(20, atas + 12, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logbook Tangkapan',
                        style:
                        TextStyle(fontSize: 13, color: Warna.teksTerang),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kapalKosong
                            ? 'Nama kapal belum diisi'
                            : pengaturan.namaKapal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: kapalKosong ? 18 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        nelayanKosong
                            ? 'Ketuk ikon pengaturan untuk mengisi nama'
                            : pengaturan.namaNelayan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: Warna.teksTerang),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Pengaturan',
                onPressed: onPengaturan,
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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
  final IconData icon;
  final String pesan;
  final Widget? aksi;

  const _KosongView({required this.icon, required this.pesan, this.aksi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Warna.teal),
            const SizedBox(height: 12),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Warna.teksRedup),
            ),
            if (aksi != null) aksi!,
          ],
        ),
      ),
    );
  }
}