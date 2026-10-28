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
      lastDate: DateTime(2100),
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