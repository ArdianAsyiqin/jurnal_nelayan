import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tangkapan.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/foto_tangkapan.dart';

/// Form tambah / ubah catatan. Mengembalikan [Tangkapan] lewat Navigator.pop.
class FormScreen extends StatefulWidget {
  final Tangkapan? awal;

  const FormScreen({super.key, this.awal});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _kunci = GlobalKey<FormState>();
  late final TextEditingController _jenis;
  late final TextEditingController _berat;
  late final TextEditingController _harga;
  late final TextEditingController _catatan;
  late DateTime _tanggal;
  double? _lat;
  double? _lng;
  String? _pathFoto;

  bool get _modeUbah => widget.awal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _jenis = TextEditingController(text: a?.jenisIkan ?? '');
    _berat = TextEditingController(text: a == null ? '' : formatAngka(a.beratKg));
    _harga = TextEditingController(
      text: a?.hargaPerKg == null ? '' : a!.hargaPerKg!.round().toString(),
    );
    _catatan = TextEditingController(text: a?.catatan ?? '');
    _tanggal = a?.tanggal ?? DateTime.now();
    _lat = a?.latitude;
    _lng = a?.longitude;
    _pathFoto = a?.pathFoto;
  }

  @override
  void dispose() {
    _jenis.dispose();
    _berat.dispose();
    _harga.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  void _ambilFoto() {
    // TODO: ganti dengan image_picker (kamera), simpan path ke _pathFoto.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Kamera akan dihubungkan pada tahap berikutnya'),
      ));
  }

  void _ambilLokasi() {
    // TODO: ganti dengan geolocator (GPS). Sementara memakai koordinat contoh.
    setState(() {
      _lat = 1.0456;
      _lng = 104.0305;
    });
  }

  void _simpan() {
    if (!_kunci.currentState!.validate()) return;
    Navigator.pop(
      context,
      Tangkapan(
        id: widget.awal?.id,
        tanggal: _tanggal,
        jenisIkan: _jenis.text.trim(),
        beratKg: parseBerat(_berat.text)!,
        hargaPerKg: _harga.text.trim().isEmpty ? null : parseHarga(_harga.text),
        latitude: _lat,
        longitude: _lng,
        pathFoto: _pathFoto,
        catatan: _catatan.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Tangkapan' : 'Tambah Tangkapan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _kunci,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _pilihTanggal,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatTanggal(_tanggal)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _jenis,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Jenis ikan'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Jenis ikan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _berat,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration:
                            const InputDecoration(labelText: 'Berat (kg)'),
                        validator: (v) {
                          final n = parseBerat(v ?? '');
                          if (n == null || n <= 0) return 'Contoh: 12,5';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _harga,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga/kg (opsional)',
                          prefixText: 'Rp ',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return parseHarga(v) == null ? 'Harga tidak valid' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _catatan,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (cuaca / kondisi laut)',
                  ),
                ),
                const SizedBox(height: 14),
                _KotakFoto(path: _pathFoto, onTap: _ambilFoto),
                const SizedBox(height: 14),
                _KartuLokasi(lat: _lat, lng: _lng, onAmbil: _ambilLokasi),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: gayaAksi(),
                    onPressed: _simpan,
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KotakFoto extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;

  const _KotakFoto({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Warna.tealSangatMuda,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Warna.teal, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 104,
          child: path != null
              ? FotoTangkapan(path: path, tinggi: 104)
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 30, color: Warna.teal),
                    SizedBox(height: 6),
                    Text(
                      'Ambil Foto Tangkapan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Warna.teal,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _KartuLokasi extends StatelessWidget {
  final double? lat;
  final double? lng;
  final VoidCallback onAmbil;

  const _KartuLokasi({
    required this.lat,
    required this.lng,
    required this.onAmbil,
  });

  @override
  Widget build(BuildContext context) {
    final ada = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Warna.garis),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi penangkapan',
                  style: TextStyle(fontSize: 13, color: Warna.teksRedup),
                ),
                const SizedBox(height: 2),
                Text(
                  ada ? formatKoordinat(lat!, lng!) : 'Belum diambil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ada ? Warna.teks : Warna.teksRedup,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            onPressed: onAmbil,
            child: Text(ada ? 'Perbarui' : 'Ambil Lokasi'),
          ),
        ],
      ),
    );
  }
}
