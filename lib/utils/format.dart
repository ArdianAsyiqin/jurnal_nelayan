// Fungsi pemformat tanpa paket tambahan (format Indonesia).

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatTanggal(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')} ${_bulan[t.month - 1]} ${t.year}';

/// 12.5 -> "12,5"; 30.0 -> "30".
String formatAngka(double v) {
  final s = v.toString();
  final bersih = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  return bersih.replaceAll('.', ',');
}

String formatBerat(double kg) => '${formatAngka(kg)} kg';

/// 562500 -> "Rp 562.500".
String formatRupiah(double nilai) {
  final angka = nilai.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < angka.length; i++) {
    if (i > 0 && (angka.length - i) % 3 == 0) buf.write('.');
    buf.write(angka[i]);
  }
  return '${nilai < 0 ? '-' : ''}Rp $buf';
}

/// Berat memakai koma desimal: "12,5" atau "12.5" -> 12.5.
double? parseBerat(String teks) =>
    double.tryParse(teks.trim().replaceAll(',', '.'));

/// Harga memakai titik ribuan: "45.000" -> 45000.
double? parseHarga(String teks) =>
    double.tryParse(teks.trim().replaceAll('.', '').replaceAll(',', ''));