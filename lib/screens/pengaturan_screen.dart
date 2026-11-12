import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/pengaturan_service.dart';


class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _kunci = GlobalKey<FormState>();
  final _nelayan = TextEditingController();
  final _kapal = TextEditingController();
  bool _otomatis = false;
  bool _memuat = true;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _nelayan.dispose();
    _kapal.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    final p = await PengaturanService.baca();
    final otomatis = await PengaturanService.bacaOtomatis();
    if (!mounted) return;
    _nelayan.text = p.namaNelayan;
    _kapal.text = p.namaKapal;
    setState(() {
      _otomatis = otomatis;
      _memuat = false;
    });
  }

  String? _validasiNama(String? v, String label) {
    final teks = (v ?? '').trim();
    if (teks.isEmpty) return '$label wajib diisi';
    if (teks.length < 2) return '$label minimal 2 huruf';
    if (teks.length > 40) return '$label maksimal 40 karakter';
    return null;
  }

  Future<void> _simpan() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      await PengaturanService.simpan(
        Pengaturan(
          namaNelayan: _nelayan.text.trim(),
          namaKapal: _kapal.text.trim(),
        ),
      );
      await PengaturanService.simpanOtomatis(_otomatis);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan pengaturan')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: _memuat
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _kunci,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nama ini ditampilkan di bagian atas layar utama.',
                  style: TextStyle(color: Warna.teksRedup),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nelayan,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration:
                  const InputDecoration(labelText: 'Nama nelayan'),
                  validator: (v) => _validasiNama(v, 'Nama nelayan'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _kapal,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration:
                  const InputDecoration(labelText: 'Nama kapal'),
                  validator: (v) => _validasiNama(v, 'Nama kapal'),
                ),
                const SizedBox(height: 8),
                const Divider(color: Warna.garis),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cadangan otomatis'),
                  subtitle: const Text(
                    'Setiap catatan ditambah, diubah, atau dihapus, '
                        'data langsung dikirim ke cloud. Jika tidak ada '
                        'internet, akan dicoba lagi nanti.',
                  ),
                  value: _otomatis,
                  onChanged: (v) => setState(() => _otomatis = v),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Mulai aktif setelah kamu menekan "Cadangkan ke '
                        'Cloud" sekali di layar utama.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Warna.teksRedup,
                    ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: gayaAksi(),
                    onPressed: _menyimpan ? null : _simpan,
                    child: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
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