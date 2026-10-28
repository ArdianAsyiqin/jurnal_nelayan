import '../models/tangkapan.dart';

/// Data contoh untuk tahap frontend. Akan digantikan oleh database SQLite.
final List<Tangkapan> dataContoh = [
  Tangkapan(
    id: 1,
    tanggal: DateTime(2026, 10, 7),
    jenisIkan: 'Kakap Merah',
    beratKg: 12.5,
    hargaPerKg: 45000,
    catatan: 'Cerah, ombak tenang',
  ),
  Tangkapan(
    id: 2,
    tanggal: DateTime(2026, 10, 5),
    jenisIkan: 'Tongkol',
    beratKg: 30,
    hargaPerKg: 28000,
    catatan: 'Berawan, arus cukup kuat',
  ),
  Tangkapan(
    id: 3,
    tanggal: DateTime(2026, 10, 3),
    jenisIkan: 'Cumi-cumi',
    beratKg: 8,
    hargaPerKg: 60000,
    catatan: 'Malam hari, memakai lampu',
  ),
  Tangkapan(
    id: 4,
    tanggal: DateTime(2026, 10, 1),
    jenisIkan: 'Tenggiri',
    beratKg: 15,
    hargaPerKg: 55000,
    catatan: 'Gerimis ringan',
  ),
];