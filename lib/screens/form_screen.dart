import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tangkapan.dart';
import '../theme.dart';
import '../utils/format.dart';

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
      lastDate: DateTime.now(),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Jenis ikan'),
                  validator: (v) {
                    final teks = (v ?? '').trim();
                    if (teks.isEmpty) return 'Jenis ikan wajib diisi';
                    if (teks.length < 2) return 'Minimal 2 huruf';
                    if (!RegExp(r'[A-Za-z]').hasMatch(teks)) {
                      return 'Harus berisi huruf';
                    }
                    return null;
                  },
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
                          final teks = (v ?? '').trim();
                          if (teks.isEmpty) return 'Berat wajib diisi';
                          final n = parseBerat(teks);
                          if (n == null) return 'Angka tidak valid. Contoh: 12,5';
                          if (n <= 0) return 'Berat harus lebih dari 0';
                          if (n > 10000) return 'Berat terlalu besar';
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
                          final teks = (v ?? '').trim();
                          if (teks.isEmpty) return null; // opsional
                          final n = parseHarga(teks);
                          if (n == null) return 'Harga tidak valid';
                          if (n <= 0) return 'Harus lebih dari 0';
                          if (n > 100000000) return 'Harga terlalu besar';
                          return null;
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