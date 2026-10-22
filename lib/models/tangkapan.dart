/// Satu catatan hasil tangkapan nelayan.
class Tangkapan {
  final int? id;
  final DateTime tanggal;
  final String jenisIkan;
  final double beratKg;
  final double? hargaPerKg;
  final double? latitude;
  final double? longitude;
  final String? pathFoto;
  final String catatan;

  const Tangkapan({
    this.id,
    required this.tanggal,
    required this.jenisIkan,
    required this.beratKg,
    this.hargaPerKg,
    this.latitude,
    this.longitude,
    this.pathFoto,
    this.catatan = '',
  });

  /// Berat x harga per kg; null bila harga tidak diisi.
  double? get estimasiPendapatan =>
      hargaPerKg == null ? null : beratKg * hargaPerKg!;

  bool get punyaLokasi => latitude != null && longitude != null;

  /// Untuk disimpan ke SQLite. Tanggal disimpan sebagai teks ISO 8601.
  Map<String, Object?> toMap() => {
        'id': id,
        'tanggal': tanggal.toIso8601String(),
        'jenis_ikan': jenisIkan,
        'berat_kg': beratKg,
        'harga_per_kg': hargaPerKg,
        'latitude': latitude,
        'longitude': longitude,
        'path_foto': pathFoto,
        'catatan': catatan,
      };

  /// Membaca satu baris SQLite menjadi objek Tangkapan.
  factory Tangkapan.fromMap(Map<String, Object?> m) => Tangkapan(
        id: m['id'] as int?,
        tanggal: DateTime.parse(m['tanggal'] as String),
        jenisIkan: m['jenis_ikan'] as String,
        beratKg: (m['berat_kg'] as num).toDouble(),
        hargaPerKg: (m['harga_per_kg'] as num?)?.toDouble(),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        pathFoto: m['path_foto'] as String?,
        catatan: (m['catatan'] as String?) ?? '',
      );
}
